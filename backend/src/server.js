require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const healthRoutes = require('./routes/health.routes');
const authRoutes = require('./routes/auth.routes');
const businessRoutes = require('./routes/business.routes');
const couponRoutes = require('./routes/coupon.routes');
const transactionRoutes = require('./routes/transaction.routes');
const notificationRoutes = require('./routes/notification.routes');
const adminRoutes = require('./routes/admin.routes');
const profileRoutes = require('./routes/profile.routes');
const reviewRoutes = require('./routes/review.routes');
const favoriteRoutes = require('./routes/favorite.routes');

const app = express();

app.use(helmet());
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: false,
}));
app.use(express.json());
app.use(morgan('dev'));

app.get('/', (req, res) => {
  res.json({
    name: 'Discount Bazzar API',
    version: '1.0.0',
    status: 'running'
  });
});

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/businesses', businessRoutes);
app.use('/api/coupons', couponRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/favorites', favoriteRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

const PORT = process.env.PORT || 4000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Discount Bazzar API running on port ${PORT}`);
});
