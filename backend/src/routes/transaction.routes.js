const express = require('express');
const router = express.Router();

router.post('/calculate', (req, res) => {
  res.json({
    success: true,
    message: 'Transaction calculation endpoint ready'
  });
});

router.post('/confirm', (req, res) => {
  res.json({
    success: true,
    message: 'Transaction confirmation endpoint ready'
  });
});

module.exports = router;
