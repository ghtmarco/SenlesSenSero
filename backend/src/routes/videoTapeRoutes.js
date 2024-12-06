const express = require("express");
const auth = require("../middleware/auth");
const {
  getAllVideoTapes,
  getVideoTapeById,
  createVideoTape,
  updateVideoTape,
  deleteVideoTape,
} = require("../controllers/videoTapeController");

const router = express.Router();

// Public routes
router.get("/", getAllVideoTapes);
router.get("/:id", getVideoTapeById);

// Protected routes (Admin only)
router.post("/", auth, createVideoTape);
router.put("/:id", auth, updateVideoTape);
router.delete("/:id", auth, deleteVideoTape);

module.exports = router;
