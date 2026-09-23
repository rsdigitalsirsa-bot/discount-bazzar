const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    success: true,
    data: [],
    message: 'Coupon listing endpoint ready'
  });
});

router.post('/claim', (req, res) => {
  res.json({
    success: true,
    message: 'Coupon claim endpoint ready'
  });
});

module.exports = router;
