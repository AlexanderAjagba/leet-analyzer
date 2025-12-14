// routes/problems.js
const express = require("express");
const router = express.Router();

/**
 * (based on America/New_York and the 3:00 AM reset).
 */
function getLeetCodeDayKeyAndRange() {
  // Current time in America/New_York (Date object)
  const now = new Date();
  const nyNow = new Date(now.toLocaleString("en-US", { timeZone: "America/New_York" }));

  // LeetCode day starts at 3:00 AM NY time
  const start = new Date(nyNow);
  start.setHours(3, 0, 0, 0);

  // If before 3 AM, we are still in yesterday's LeetCode day
  if (nyNow.getHours() < 3) {
    start.setDate(start.getDate() - 1);
  }

  const end = new Date(start);
  end.setDate(end.getDate() + 1);

  // Format start date as YYYY-MM-DD in NY time
  const dayKey = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/New_York",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(start);

  return { dayKey, start, end };
}

router.get("/problem-of-the-day", async (req, res) => {
  try {
    const API_BASE_URL = process.env.LEETCODE_API_URL;
    if (!API_BASE_URL) {
      return res.status(503).json({ error: "LEETCODE_API_URL is not set." });
    }

    const dailyproblem = globalThis.dbClient
      .db("leettrack")
      .collection("dailyproblem");

    const { dayKey } = getLeetCodeDayKeyAndRange();

    // 1) Try Mongo first (stable key)
    let problemData = await dailyproblem.findOne({ leetcodeDay: dayKey });

    // 2) If missing, fetch from your REST API and upsert
    if (!problemData) {
      const response = await fetch(`${API_BASE_URL}/daily`);
      if (!response.ok) {
        return res.status(502).json({
          error: "Failed to fetch problem of the day from external API.",
          status: response.status,
        });
      }

      const apiData = await response.json();

      // Store the fields you care about
      problemData = {
        leetcodeDay: dayKey,
        questionLink: apiData.questionLink,
        questionTitle: apiData.questionTitle,
        questionId: apiData.questionId,
        questionFrontendId: apiData.questionFrontendId,
        difficulty: apiData.difficulty,
        date: apiData.date,
        fetchedAt: new Date(),
      };

      // Upsert prevents duplicates if two requests hit at the same time
      await dailyproblem.updateOne(
        { leetcodeDay: dayKey },
        { $set: problemData },
        { upsert: true }
      );
    }

    // 3) Return a clean response
    return res.json({
      link: problemData.questionLink,
      title: problemData.questionTitle,
      difficulty: problemData.difficulty,
      date: problemData.date,
    });
  } catch (error) {
    console.error("Error fetching problem of the day:", error);
    return res.status(500).json({ error: "Failed to fetch problem of the day" });
  }
});

module.exports = router;
