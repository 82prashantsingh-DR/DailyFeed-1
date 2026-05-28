const express = require('express');
const router = express.Router();
const marketService = require('../services/marketService');

// Get Indian market data
router.get('/india', async (req, res) => {
  try {
    const data = await marketService.getIndianMarket();
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get global market data
router.get('/global', async (req, res) => {
  try {
    const data = await marketService.getGlobalMarket();
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get commodities
router.get('/commodities', async (req, res) => {
  try {
    const data = await marketService.getCommodities();
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get cryptocurrencies
router.get('/crypto', async (req, res) => {
  try {
    const data = await marketService.getCryptoMarket();
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get complete dashboard
router.get('/dashboard', async (req, res) => {
  try {
    const data = await marketService.getDashboard();
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get specific index
router.get('/index/:name', async (req, res) => {
  try {
    const data = await marketService.getIndex(req.params.name);
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
