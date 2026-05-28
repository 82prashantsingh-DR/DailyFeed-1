const express = require('express');
const router = express.Router();
const newsService = require('../services/newsService');

// Get India news
router.get('/india', async (req, res) => {
  try {
    const pageSize = parseInt(req.query.pageSize) || 20;
    const data = await newsService.getIndiaNews(pageSize);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get global news
router.get('/global', async (req, res) => {
  try {
    const pageSize = parseInt(req.query.pageSize) || 20;
    const data = await newsService.getGlobalNews(pageSize);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Search news
router.get('/search', async (req, res) => {
  try {
    const query = req.query.query || req.query.q;
    if (!query) {
      return res.status(400).json({
        success: false,
        error: 'Query parameter required',
      });
    }

    const pageSize = parseInt(req.query.pageSize) || 20;
    const sortBy = req.query.sortBy || 'publishedAt';
    const language = req.query.language || 'en';

    const data = await newsService.searchNews(query, pageSize, sortBy, language);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get news by category
router.get('/category/:category', async (req, res) => {
  try {
    const category = req.params.category;
    const country = req.query.country || 'in';
    const pageSize = parseInt(req.query.pageSize) || 20;

    const data = await newsService.getNewsByCategory(category, country, pageSize);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get RSS feeds
router.get('/rss', async (req, res) => {
  try {
    const region = req.query.region || 'india';
    const limit = parseInt(req.query.limit) || 50;

    const data = await newsService.getRSSNews(region, limit);
    res.json({
      success: true,
      source: 'RSS Feeds',
      region: region,
      totalArticles: data.length,
      articles: data,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get headlines by country
router.get('/headlines', async (req, res) => {
  try {
    const country = req.query.country || 'in';
    const pageSize = parseInt(req.query.pageSize) || 20;

    const data = await newsService.getHeadlines(country, pageSize);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
