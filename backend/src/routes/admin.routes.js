const express = require('express');
const router = express.Router();

router.get('/dashboard', (req, res) => {
  res.json({
    success: true,
    message: 'Admin dashboard endpoint ready'
  });
});

module.exports = router;
