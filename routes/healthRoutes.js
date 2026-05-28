const express = require('express');
const router = express.Router();

// Health check endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    message: 'DailyFeed API is running',
    endpoints: {
      news: {
        india: '/api/news/india',
        global: '/api/news/global',
        search: '/api/news/search?query=keyword',
        category: '/api/news/category/technology',
        rss: '/api/news/rss?region=india',
        headlines: '/api/news/headlines?country=in',
      },
      market: {
        india: '/api/market/india',
        global: '/api/market/global',
        commodities: '/api/market/commodities',
        crypto: '/api/market/crypto',
        dashboard: '/api/market/dashboard',
        index: '/api/market/index/nifty50',
      },
    },
  });
});

module.exports = router;
