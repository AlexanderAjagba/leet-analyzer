// middleware/cache.js
const CACHE_DURATION_MS = 5 * 60 * 1000; // 5 minutes

function pickDifficultyTotal(arr, difficulty) {
  if (!Array.isArray(arr)) return { count: null, submissions: null };
  const row = arr.find((x) => x.difficulty === difficulty);
  return {
    count: row?.count ?? null,
    submissions: row?.submissions ?? null,
  };
}

async function cacheMiddleware(req, res, next) {
  const userData = globalThis.dbClient.db("leettrack").collection("data");
  const username = req.params.userId;

  if (!username) {
    return res.status(400).json({ error: "Username parameter is required." });
  }

  try {
    const now = new Date();

    // 1) Check Mongo first
    const userDoc = await userData.findOne({ username });

    if (userDoc?.cachedAt) {
      const cachedTime = new Date(userDoc.cachedAt);
      const isFresh = now.getTime() - cachedTime.getTime() < CACHE_DURATION_MS;

      // If we recently confirmed user doesn't exist, stop early
      if (isFresh && userDoc.notFound === true) {
        return res
          .status(404)
          .json({ error: `LeetCode user '${username}' not found.` });
      }

      // Fresh data → attach and proceed
      if (isFresh) {
        req.userData = userDoc;
        return next();
      }
      // stale → continue to fetch
    }

    // 2) Missing or stale → fetch from alfa-leetcode-api REST endpoints
    const API_BASE_URL = process.env.LEETCODE_API_URL;
    if (!API_BASE_URL) {
      // If API URL missing but we have DB data, serve it; else fail
      if (userDoc) {
        req.userData = userDoc;
        return next();
      }
      return res.status(503).json({ error: "LEETCODE_API_URL is not set." });
    }

    const solvedUrl = `${API_BASE_URL}/${username}/solved`;
    const subsUrl = `${API_BASE_URL}/${username}/submission?limit=20`;

    const [solvedRes, subsRes] = await Promise.all([
      fetch(solvedUrl),
      fetch(subsUrl),
    ]);

    // If user doesn't exist on external API, cache notFound marker
    if (solvedRes.status === 404) {
      await userData.updateOne(
        { username },
        {
          $set: {
            username,
            cachedAt: now.toISOString(),
            notFound: true,
          },
        },
        { upsert: true }
      );

      return res
        .status(404)
        .json({ error: `LeetCode user '${username}' not found.` });
    }

    // If solved endpoint fails, fallback to stale Mongo (if any)
    if (!solvedRes.ok) {
      if (userDoc) {
        req.userData = userDoc;
        return next();
      }
      return res.status(502).json({
        error: "Failed to fetch solved stats from external API.",
        status: solvedRes.status,
      });
    }

    const solved = await solvedRes.json();

    // Submissions endpoint is optional: if it fails, we keep it empty (or keep old if present)
    let recentSubmissions = [];
    if (subsRes.ok) {
      const subsJson = await subsRes.json();
      recentSubmissions =
        subsJson?.submission ||
        subsJson?.submissions ||
        (Array.isArray(subsJson) ? subsJson : []);
    } else if (userDoc?.recentSubmissions) {
      // preserve existing submissions if present and API fails
      recentSubmissions = userDoc.recentSubmissions;
    }

    // Map alfa payload → your schema
    const acAll = pickDifficultyTotal(solved.acSubmissionNum, "All");
    const acEasy = pickDifficultyTotal(solved.acSubmissionNum, "Easy");
    const acMed = pickDifficultyTotal(solved.acSubmissionNum, "Medium");
    const acHard = pickDifficultyTotal(solved.acSubmissionNum, "Hard");

    const normalized = {
      username,
      cachedAt: now.toISOString(),
      notFound: false,

      // Your routes expect these
      totalSolved: solved.solvedProblem ?? acAll.count ?? null,

      easySolved: solved.easySolved ?? acEasy.count ?? null,
      mediumSolved: solved.mediumSolved ?? acMed.count ?? null,
      hardSolved: solved.hardSolved ?? acHard.count ?? null,

      // These represent accepted submissions (from acSubmissionNum.submissions)
      totalEasy: acEasy.submissions ?? null,
      totalMedium: acMed.submissions ?? null,
      totalHard: acHard.submissions ?? null,

      // Option A stats breakdown (attempt/submission breakdown)
      totalSubmissions: solved.totalSubmissionNum ?? null,

      // Keep originals too (optional, useful later)
      acSubmissionNum: solved.acSubmissionNum ?? null,
      totalSubmissionNum: solved.totalSubmissionNum ?? null,

      // recent submissions cached in Mongo
      recentSubmissions,
    };

    await userData.updateOne(
      { username },
      { $set: normalized },
      { upsert: true }
    );

    req.userData = normalized;
    return next();
  } catch (err) {
    console.error(`Error in cacheMiddleware for user ${username}:`, err);
    return res.status(500).json({ error: "Unexpected error in cache middleware." });
  }
}

module.exports = cacheMiddleware;
