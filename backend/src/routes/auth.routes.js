const express = require('express');
const router = express.Router();

router.post('/send-otp', (req, res) => {
  res.json({
    success: true,
    message: 'OTP service endpoint ready',
    demo: true
  });
});

router.post('/verify-otp', (req, res) => {
  res.json({
    success: true,
    message: 'OTP verification endpoint ready',
    demo: true
  });
});

module.exports = router;
