const express = require("express");
const multer = require("multer");
const cors = require("cors");
const path = require('path');
const fs = require('fs');
require("dotenv").config();
const db = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const videoTapeRoutes = require("./routes/videoTapeRoutes");
const app = express();

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../assets/images');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Setup storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Use timestamp + original filename extension
    const ext = path.extname(file.originalname);
    const filename = `${Date.now()}${ext}`;
    cb(null, filename);
  }
});

const upload = multer({ storage: storage });

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/videotapes", videoTapeRoutes);

// Serve static files
app.use('/uploads', express.static(path.join(__dirname, '../assets/images')));

// Upload endpoint
app.post("/api/upload", upload.single("image"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }
    
    // Return relative URL
    const imageUrl = `/uploads/${req.file.filename}`;
    res.json({ url: imageUrl });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Test route
app.get("/api/test", async (req, res) => {
  try {
    const [rows] = await db.query("SELECT 1 + 1 AS result");
    res.json({
      message: "Backend is working!",
      dbConnection: "Database connected successfully",
      result: rows[0].result,
    });
  } catch (error) {
    res.status(500).json({
      message: "Error connecting to database",
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
