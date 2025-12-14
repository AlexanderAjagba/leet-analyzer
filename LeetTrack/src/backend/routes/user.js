// routes/user.js
const express = require("express");
const router = express.Router();

const cacheMiddleware = require("../middleware/cache");

// Ensure cache runs only when :userId exists
router.use("/:userId", cacheMiddleware);

function getAllDifficultyTotals(totalSubmissions) {
  if (!Array.isArray(totalSubmissions)) return { allCount: null, allAttempts: null };
  const all = totalSubmissions.find((x) => x.difficulty === "All");
  return {
    allCount: all?.count ?? null,
    allAttempts: all?.submissions ?? null,
  };
}

// /user/:userId/stats
router.get("/:userId/stats", (req, res) => {
  const userId = req.params.userId;
  const doc = req.userData;

  if (!doc) return res.status(500).json({ error: "Cache middleware did not attach data." });
  if (doc.notFound === true) return res.status(404).json({ error: "User not found" });

  const { allCount, allAttempts } = getAllDifficultyTotals(doc.totalSubmissions);

  return res.json({
    username: userId,
    totalSolved: doc.totalSolved,
    ranking: doc.ranking ?? null,

    totalSubmissionsCount: allCount,
    totalSubmissionsAttempts: allAttempts,
    totalSubmissionsByDifficulty: doc.totalSubmissions,
  });
});

// /user/:userId/easy
router.get("/:userId/easy", (req, res) => {
  const userId = req.params.userId;
  const doc = req.userData;

  if (!doc) return res.status(500).json({ error: "Cache middleware did not attach data." });
  if (doc.notFound === true) return res.status(404).json({ error: "User not found" });

  return res.json({
    username: userId,
    easySolved: doc.easySolved,
    totalEasy: doc.totalEasy,
  });
});

// /user/:userId/medium
router.get("/:userId/medium", (req, res) => {
  const userId = req.params.userId;
  const doc = req.userData;

  if (!doc) return res.status(500).json({ error: "Cache middleware did not attach data." });
  if (doc.notFound === true) return res.status(404).json({ error: "User not found" });

  return res.json({
    username: userId,
    mediumSolved: doc.mediumSolved,
    totalMedium: doc.totalMedium,
  });
});

// /user/:userId/hard
router.get("/:userId/hard", (req, res) => {
  const userId = req.params.userId;
  const doc = req.userData;

  if (!doc) return res.status(500).json({ error: "Cache middleware did not attach data." });
  if (doc.notFound === true) return res.status(404).json({ error: "User not found" });

  return res.json({
    username: userId,
    hardSolved: doc.hardSolved,
    totalHard: doc.totalHard,
  });
});

// /user/:userId/recent-submissions
router.get("/:userId/recent-submissions", (req, res) => {
  const userId = req.params.userId;
  const doc = req.userData;

  if (!doc) return res.status(500).json({ error: "Cache middleware did not attach data." });
  if (doc.notFound === true) return res.status(404).json({ error: "User not found" });

  const recent = (doc.recentSubmissions || []).slice(0, 10);

  const formatted = recent.map((sub) => ({
    title: sub.title,
    titleSlug: sub.titleSlug,
    status: sub.statusDisplay ?? sub.status ?? null,
    language: sub.lang ?? sub.language ?? null,
    timestamp: sub.timestamp
      ? new Date(Number(sub.timestamp) * 1000).toISOString()
      : null,
  }));

  return res.json({ username: userId, submissions: formatted });
});

module.exports = router;
