// database/server.js
require("dotenv").config();

const express = require("express");
const { MongoClient, ServerApiVersion } = require("mongodb");

const userRoutes = require("../routes/user");
const problemRoutes = require("../routes/problems");
const { rate } = require("../middleware/ratelimiter");

const uri = process.env.DATABASE_URL;
if (!uri) {
  throw new Error("DATABASE_URL is missing.");
}

const app = express();

const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
});

async function startServer() {
  await client.connect();
  globalThis.dbClient = client;
  console.log("Connected to MongoDB!");

  const port = process.env.PORT || 4000;
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

// Global middleware
app.use(express.json());
app.use(rate);

// Routes
app.use("/user", userRoutes);
app.use("/problems", problemRoutes);

startServer().catch((err) => {
  console.error(err);
  process.exit(1);
});
