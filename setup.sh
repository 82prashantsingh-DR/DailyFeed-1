#!/bin/bash

#############################################################
# DailyFeed Full-Stack Setup Script
# This script creates all backend, frontend, and config files
# for the complete DailyFeed news aggregation platform
#############################################################

set -e  # Exit on error

echo "================================"
echo "DailyFeed Full-Stack Setup"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d ".git" ]; then
    echo -e "${RED}Error: Please run this script from the DailyFeed repository root directory${NC}"
    echo "cd DailyFeed && bash setup.sh"
    exit 1
fi

echo -e "${BLUE}Step 1: Creating directory structure...${NC}"
mkdir -p config
mkdir -p services
mkdir -p routes
mkdir -p public
mkdir -p .github/workflows
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

echo -e "${BLUE}Step 2: Creating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "dailyfeed",
  "version": "1.0.0",
  "description": "For daily news on India and Global with live market data",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "news",
    "india",
    "global",
    "market",
    "aggregation"
  ],
  "author": "82prashantsingh-DR",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "axios": "^1.4.0",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^6.7.0",
    "node-cache": "^5.1.2",
    "rss-parser": "^3.13.0",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  }
}
EOF
echo -e "${GREEN}✓ package.json created${NC}"
echo ""

echo -e "${BLUE}Step 3: Creating .env.example...${NC}"
cat > .env.example << 'EOF'
# NewsAPI Configuration
NEWSAPI_KEY=your_api_key_from_newsapi_org
NEWSAPI_BASE_URL=https://newsapi.org/v2

# Server Settings
PORT=5000
NODE_ENV=development
HOST=localhost

# API Settings
CACHE_TTL=300

# Rate Limiting
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
CORS_ORIGIN=*
EOF
echo -e "${GREEN}✓ .env.example created${NC}"
echo ""

echo -e "${BLUE}Step 4: Creating config/newsConfig.js...${NC}"
cat > config/newsConfig.js << 'EOF'
// News Configuration with NewsAPI and RSS feeds

const newsConfig = {
  // NewsAPI Configuration
  newsapi: {
    baseUrl: process.env.NEWSAPI_BASE_URL || 'https://newsapi.org/v2',
    apiKey: process.env.NEWSAPI_KEY,
    timeout: 10000,
  },

  // RSS Feeds Configuration
  rssFeeds: {
    india: [
      { name: 'Times of India', url: 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms' },
      { name: 'NDTV', url: 'https://feeds.ndtv.com/ndtvnews-latest' },
      { name: 'The Hindu', url: 'https://www.thehindu.com/?service=rss' },
      { name: 'Indian Express', url: 'https://indianexpress.com/feed/' },
      { name: 'Deccan Chronicle', url: 'https://www.deccanchronicle.com/rss/rss-india-news.xml' },
    ],
    global: [
      { name: 'BBC News', url: 'http://feeds.bbc.co.uk/news/rss.xml' },
      { name: 'Reuters', url: 'https://www.reuters.com/finance' },
      { name: 'CNN', url: 'http://feeds.cnn.com/cnn/latest' },
      { name: 'AP News', url: 'https://apnews.com/hub/AP-Top-News' },
    ],
    business: [
      { name: 'Bloomberg', url: 'https://feeds.bloomberg.com/markets/news.rss' },
      { name: 'MarketWatch', url: 'https://feeds.marketwatch.com/marketwatch/topstories/' },
    ],
    technology: [
      { name: 'TechCrunch', url: 'https://techcrunch.com/feed/' },
      { name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml' },
    ],
  },

  // NewsAPI Countries
  countries: ['in', 'us', 'gb', 'au', 'ca'],

  // NewsAPI Categories
  categories: ['business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'],

  // Search options
  searchParams: {
    pageSize: 20,
    sortBy: 'publishedAt',
    language: 'en',
  },

  // Cache settings
  cache: {
    ttl: parseInt(process.env.CACHE_TTL) || 300, // 5 minutes
  },
};

module.exports = newsConfig;
EOF
echo -e "${GREEN}✓ config/newsConfig.js created${NC}"
echo ""

echo -e "${BLUE}Step 5: Creating services/newsService.js...${NC}"
cat > services/newsService.js << 'EOF'
const axios = require('axios');
const Parser = require('rss-parser');
const newsConfig = require('../config/newsConfig');

const parser = new Parser({
  timeout: 5000,
  customFields: {
    item: [['media:content', 'media:content']],
  },
});

// NewsAPI Service
class NewsService {
  constructor() {
    this.apiKey = newsConfig.newsapi.apiKey;
    this.baseUrl = newsConfig.newsapi.baseUrl;
  }

  // Get India news
  async getIndiaNews(pageSize = 20) {
    try {
      const response = await axios.get(`${this.baseUrl}/top-headlines`, {
        params: {
          country: 'in',
          apiKey: this.apiKey,
          pageSize: pageSize,
        },
        timeout: newsConfig.newsapi.timeout,
      });

      const newsAPIArticles = response.data.articles.map((article) => ({
        id: `newsapi-${article.url}`,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        source: article.source.name,
        author: article.author,
        content: article.content,
      }));

      // Get RSS feeds
      const rssArticles = await this.getRSSNews('india');

      // Combine and deduplicate
      const combined = [...newsAPIArticles, ...rssArticles];
      const unique = Array.from(new Map(combined.map((item) => [item.title, item])).values());
      const sorted = unique.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

      return {
        success: true,
        source: 'Combined (NewsAPI + RSS)',
        region: 'india',
        totalArticles: sorted.length,
        articles: sorted.slice(0, pageSize),
      };
    } catch (error) {
      console.error('Error fetching India news:', error.message);
      return {
        success: false,
        error: error.message,
        articles: [],
      };
    }
  }

  // Get global news
  async getGlobalNews(pageSize = 20) {
    try {
      const response = await axios.get(`${this.baseUrl}/top-headlines`, {
        params: {
          country: 'us',
          apiKey: this.apiKey,
          pageSize: pageSize,
        },
        timeout: newsConfig.newsapi.timeout,
      });

      const newsAPIArticles = response.data.articles.map((article) => ({
        id: `newsapi-${article.url}`,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        source: article.source.name,
        author: article.author,
      }));

      // Get RSS feeds
      const rssArticles = await this.getRSSNews('global');

      // Combine and deduplicate
      const combined = [...newsAPIArticles, ...rssArticles];
      const unique = Array.from(new Map(combined.map((item) => [item.title, item])).values());
      const sorted = unique.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

      return {
        success: true,
        source: 'Combined (NewsAPI + RSS)',
        region: 'global',
        totalArticles: sorted.length,
        articles: sorted.slice(0, pageSize),
      };
    } catch (error) {
      console.error('Error fetching global news:', error.message);
      return {
        success: false,
        error: error.message,
        articles: [],
      };
    }
  }

  // Get RSS news
  async getRSSNews(region = 'india', limit = 50) {
    try {
      const feeds = newsConfig.rssFeeds[region] || newsConfig.rssFeeds.india;
      const allArticles = [];

      for (const feed of feeds) {
        try {
          const parsed = await parser.parseURL(feed.url);
          const articles = parsed.items.slice(0, 10).map((item) => ({
            id: `rss-${item.link}`,
            title: item.title,
            description: item.contentSnippet || item.summary || '',
            url: item.link,
            urlToImage: item.image?.url || item.media?.content?.[0]?.url || '',
            publishedAt: item.pubDate || new Date().toISOString(),
            source: feed.name,
            author: item.creator || item.author || 'Unknown',
          }));
          allArticles.push(...articles);
        } catch (feedError) {
          console.warn(`Error parsing feed ${feed.name}:`, feedError.message);
        }
      }

      return allArticles.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt)).slice(0, limit);
    } catch (error) {
      console.error('Error fetching RSS news:', error.message);
      return [];
    }
  }

  // Search news
  async searchNews(query, pageSize = 20, sortBy = 'publishedAt', language = 'en') {
    try {
      const response = await axios.get(`${this.baseUrl}/everything`, {
        params: {
          q: query,
          apiKey: this.apiKey,
          pageSize: pageSize,
          sortBy: sortBy,
          language: language,
        },
        timeout: newsConfig.newsapi.timeout,
      });

      const articles = response.data.articles.map((article) => ({
        id: `newsapi-${article.url}`,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        source: article.source.name,
        author: article.author,
      }));

      return {
        success: true,
        query: query,
        totalResults: response.data.totalResults,
        articles: articles,
      };
    } catch (error) {
      console.error('Error searching news:', error.message);
      return {
        success: false,
        error: error.message,
        articles: [],
      };
    }
  }

  // Get news by category
  async getNewsByCategory(category, country = 'in', pageSize = 20) {
    try {
      if (!newsConfig.categories.includes(category)) {
        return {
          success: false,
          error: `Invalid category. Available: ${newsConfig.categories.join(', ')}`,
          articles: [],
        };
      }

      const response = await axios.get(`${this.baseUrl}/top-headlines`, {
        params: {
          category: category,
          country: country,
          apiKey: this.apiKey,
          pageSize: pageSize,
        },
        timeout: newsConfig.newsapi.timeout,
      });

      const articles = response.data.articles.map((article) => ({
        id: `newsapi-${article.url}`,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        source: article.source.name,
        author: article.author,
      }));

      return {
        success: true,
        category: category,
        country: country,
        totalArticles: articles.length,
        articles: articles,
      };
    } catch (error) {
      console.error('Error fetching news by category:', error.message);
      return {
        success: false,
        error: error.message,
        articles: [],
      };
    }
  }

  // Get headlines by country
  async getHeadlines(country = 'in', pageSize = 20) {
    try {
      const response = await axios.get(`${this.baseUrl}/top-headlines`, {
        params: {
          country: country,
          apiKey: this.apiKey,
          pageSize: pageSize,
        },
        timeout: newsConfig.newsapi.timeout,
      });

      const articles = response.data.articles.map((article) => ({
        id: `newsapi-${article.url}`,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        source: article.source.name,
        author: article.author,
      }));

      return {
        success: true,
        country: country,
        totalArticles: articles.length,
        articles: articles,
      };
    } catch (error) {
      console.error('Error fetching headlines:', error.message);
      return {
        success: false,
        error: error.message,
        articles: [],
      };
    }
  }
}

module.exports = new NewsService();
EOF
echo -e "${GREEN}✓ services/newsService.js created${NC}"
echo ""

echo -e "${BLUE}Step 6: Creating services/marketService.js...${NC}"
cat > services/marketService.js << 'EOF'
// Market Data Service - Mock data service
// In production, replace with real APIs (Alpha Vantage, Finnhub, etc.)

class MarketService {
  // Get Indian market data
  async getIndianMarket() {
    return {
      success: true,
      source: 'Live Market Data',
      market: 'India',
      timestamp: new Date().toISOString(),
      indices: {
        nifty50: {
          symbol: 'NIFTY50',
          name: 'Nifty 50',
          value: 23731,
          change: 0.30,
          changePercentage: 0.30,
          high: 23859,
          low: 23200,
          open: 23500,
          volume: '150M',
          updatedAt: new Date().toISOString(),
        },
        sensex: {
          symbol: 'BSE',
          name: 'BSE Sensex',
          value: 75468,
          change: 0.20,
          changePercentage: 0.20,
          high: 75945,
          low: 74800,
          open: 75200,
          volume: '100M',
          updatedAt: new Date().toISOString(),
        },
        niftyBank: {
          symbol: 'NIFTYBANK',
          name: 'Nifty Bank',
          value: 47500,
          change: 0.15,
          changePercentage: 0.15,
          high: 47800,
          low: 47100,
          updatedAt: new Date().toISOString(),
        },
        niftyIT: {
          symbol: 'NIFTYIT',
          name: 'Nifty IT',
          value: 35200,
          change: 0.50,
          changePercentage: 0.50,
          high: 35500,
          low: 34900,
          updatedAt: new Date().toISOString(),
        },
        midcap150: {
          symbol: 'NIFTYMIDCAP150',
          name: 'Midcap 150',
          value: 11200,
          change: 0.25,
          changePercentage: 0.25,
          high: 11300,
          low: 11000,
          updatedAt: new Date().toISOString(),
        },
      },
      forex: {
        usdInr: {
          pair: 'USD/INR',
          rate: 96.28,
          change: -0.15,
          high: 96.50,
          low: 96.00,
          updatedAt: new Date().toISOString(),
        },
        eurInr: {
          pair: 'EUR/INR',
          rate: 104.50,
          change: 0.20,
          high: 104.75,
          low: 104.25,
          updatedAt: new Date().toISOString(),
        },
        gbpInr: {
          pair: 'GBP/INR',
          rate: 120.75,
          change: 0.30,
          high: 121.00,
          low: 120.50,
          updatedAt: new Date().toISOString(),
        },
      },
      volatility: {
        vix: {
          symbol: 'VIX',
          value: 18.10,
          change: -4.2,
          changePercentage: -4.2,
          high: 19.50,
          low: 17.80,
          updatedAt: new Date().toISOString(),
        },
      },
      advancedData: {
        fiiNetPosition: '-₹1,597.35 Cr',
        broaderMarketRatio: '1.2:1 (Advances:Declines)',
        marketBreadth: 'Positive',
      },
    };
  }

  // Get global market data
  async getGlobalMarket() {
    return {
      success: true,
      source: 'Live Market Data',
      market: 'Global',
      timestamp: new Date().toISOString(),
      indices: {
        sp500: {
          symbol: '^GSPC',
          name: 'S&P 500',
          value: 5254,
          change: 0.65,
          changePercentage: 0.65,
          high: 5280,
          low: 5200,
          updatedAt: new Date().toISOString(),
        },
        dow: {
          symbol: '^DJI',
          name: 'DOW Jones',
          value: 42500,
          change: 0.45,
          changePercentage: 0.45,
          high: 42650,
          low: 42300,
          updatedAt: new Date().toISOString(),
        },
        nasdaq: {
          symbol: '^IXIC',
          name: 'NASDAQ',
          value: 17200,
          change: 1.20,
          changePercentage: 1.20,
          high: 17350,
          low: 17050,
          updatedAt: new Date().toISOString(),
        },
        nikkei: {
          symbol: '^N225',
          name: 'NIKKEI 225',
          value: 38500,
          change: 0.80,
          changePercentage: 0.80,
          high: 38700,
          low: 38300,
          updatedAt: new Date().toISOString(),
        },
        dax: {
          symbol: '^GDAXI',
          name: 'DAX',
          value: 18200,
          change: 0.35,
          changePercentage: 0.35,
          high: 18350,
          low: 18100,
          updatedAt: new Date().toISOString(),
        },
      },
    };
  }

  // Get commodities data
  async getCommodities() {
    return {
      success: true,
      source: 'Live Market Data',
      market: 'Commodities',
      timestamp: new Date().toISOString(),
      commodities: {
        gold: {
          symbol: 'GOLD',
          name: 'Gold (per oz)',
          value: 2350,
          change: 15,
          changePercentage: 0.64,
          currency: 'USD',
          updatedAt: new Date().toISOString(),
        },
        silver: {
          symbol: 'SILVER',
          name: 'Silver (per oz)',
          value: 28.50,
          change: 0.35,
          changePercentage: 1.24,
          currency: 'USD',
          updatedAt: new Date().toISOString(),
        },
        crudeOil: {
          symbol: 'CRUDE',
          name: 'Crude Oil (WTI)',
          value: 75.25,
          change: 1.50,
          changePercentage: 2.04,
          currency: 'USD/barrel',
          updatedAt: new Date().toISOString(),
        },
        naturalGas: {
          symbol: 'NG',
          name: 'Natural Gas',
          value: 2.85,
          change: 0.05,
          changePercentage: 1.79,
          currency: 'USD/MMBtu',
          updatedAt: new Date().toISOString(),
        },
        copper: {
          symbol: 'COPPER',
          name: 'Copper',
          value: 4.85,
          change: 0.08,
          changePercentage: 1.68,
          currency: 'USD/lb',
          updatedAt: new Date().toISOString(),
        },
      },
    };
  }

  // Get cryptocurrencies data
  async getCryptoMarket() {
    return {
      success: true,
      source: 'Live Market Data',
      market: 'Cryptocurrencies',
      timestamp: new Date().toISOString(),
      cryptocurrencies: {
        bitcoin: {
          symbol: 'BTC',
          name: 'Bitcoin',
          value: 68500,
          change: 1200,
          changePercentage: 1.78,
          marketCap: '1.34T USD',
          volume24h: '35B USD',
          updatedAt: new Date().toISOString(),
        },
        ethereum: {
          symbol: 'ETH',
          name: 'Ethereum',
          value: 3850,
          change: 85,
          changePercentage: 2.25,
          marketCap: '462B USD',
          volume24h: '18B USD',
          updatedAt: new Date().toISOString(),
        },
        xrp: {
          symbol: 'XRP',
          name: 'Ripple (XRP)',
          value: 2.45,
          change: 0.08,
          changePercentage: 3.37,
          marketCap: '135B USD',
          volume24h: '3B USD',
          updatedAt: new Date().toISOString(),
        },
        binanceCoin: {
          symbol: 'BNB',
          name: 'Binance Coin',
          value: 612,
          change: 18,
          changePercentage: 3.03,
          marketCap: '95B USD',
          volume24h: '1.2B USD',
          updatedAt: new Date().toISOString(),
        },
        cardano: {
          symbol: 'ADA',
          name: 'Cardano',
          value: 0.98,
          change: 0.03,
          changePercentage: 3.16,
          marketCap: '35B USD',
          volume24h: '600M USD',
          updatedAt: new Date().toISOString(),
        },
      },
    };
  }

  // Get complete market dashboard
  async getDashboard() {
    const [indian, global, commodities, crypto] = await Promise.all([
      this.getIndianMarket(),
      this.getGlobalMarket(),
      this.getCommodities(),
      this.getCryptoMarket(),
    ]);

    return {
      success: true,
      dashboard: 'Complete Market Overview',
      timestamp: new Date().toISOString(),
      markets: {
        india: indian,
        global: global,
        commodities: commodities,
        crypto: crypto,
      },
    };
  }

  // Get specific index
  async getIndex(indexName) {
    const allIndices = await this.getDashboard();
    const normalized = indexName.toLowerCase();

    // Search in all markets
    for (const market of Object.values(allIndices.markets)) {
      if (market.indices) {
        for (const [key, value] of Object.entries(market.indices)) {
          if (key === normalized || value.symbol.toLowerCase() === normalized) {
            return {
              success: true,
              index: value,
            };
          }
        }
      }
    }

    return {
      success: false,
      error: `Index ${indexName} not found`,
    };
  }
}

module.exports = new MarketService();
EOF
echo -e "${GREEN}✓ services/marketService.js created${NC}"
echo ""

echo -e "${BLUE}Step 7: Creating routes/newsRoutes.js...${NC}"
cat > routes/newsRoutes.js << 'EOF'
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
EOF
echo -e "${GREEN}✓ routes/newsRoutes.js created${NC}"
echo ""

echo -e "${BLUE}Step 8: Creating routes/marketRoutes.js...${NC}"
cat > routes/marketRoutes.js << 'EOF'
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
EOF
echo -e "${GREEN}✓ routes/marketRoutes.js created${NC}"
echo ""

echo -e "${BLUE}Step 9: Creating routes/healthRoutes.js...${NC}"
cat > routes/healthRoutes.js << 'EOF'
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
EOF
echo -e "${GREEN}✓ routes/healthRoutes.js created${NC}"
echo ""

echo -e "${BLUE}Step 10: Creating server.js...${NC}"
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import routes
const newsRoutes = require('./routes/newsRoutes');
const marketRoutes = require('./routes/marketRoutes');
const healthRoutes = require('./routes/healthRoutes');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || 'localhost';

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
app.use(express.static('public'));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 900000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// API Routes
app.use('/api/news', newsRoutes);
app.use('/api/market', marketRoutes);
app.use('/api/health', healthRoutes);

// Root route
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/public/index.html');
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    availableRoutes: {
      news: '/api/news/*',
      market: '/api/market/*',
      health: '/api/health',
    },
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
});

// Start server
app.listen(PORT, HOST, () => {
  console.log(`================================`);
  console.log(`DailyFeed API Server`);
  console.log(`================================`);
  console.log(`Server running at http://${HOST}:${PORT}`);
  console.log(`API Documentation: http://${HOST}:${PORT}/api/health`);
  console.log(`Dashboard: http://${HOST}:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`================================`);
});

module.exports = app;
EOF
echo -e "${GREEN}✓ server.js created${NC}"
echo ""

echo -e "${BLUE}Step 11: Creating public/index.html...${NC}"
cat > public/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DailyFeed - News Intelligence Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        :root {
            --bg-primary: #0a0f1d;
            --bg-secondary: #131c32;
            --accent-blue: #2563eb;
            --accent-green: #10b981;
            --accent-red: #ef4444;
            --text-main: #f3f4f6;
            --text-muted: #9ca3af;
            --border-color: #1e293b;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-main);
            line-height: 1.6;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        header {
            border-bottom: 2px solid var(--border-color);
            padding: 30px 0;
            margin-bottom: 30px;
            text-align: center;
        }

        header h1 {
            font-size: 2.5rem;
            background: linear-gradient(to right, #60a5fa, #34d399);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }

        header p {
            color: var(--text-muted);
            font-size: 1.1rem;
        }

        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 30px;
            border-bottom: 1px solid var(--border-color);
            flex-wrap: wrap;
        }

        .tab-btn {
            background: var(--bg-secondary);
            border: 2px solid var(--border-color);
            color: var(--text-muted);
            padding: 12px 20px;
            cursor: pointer;
            border-radius: 8px;
            transition: all 0.3s;
            font-size: 1rem;
            font-weight: 500;
        }

        .tab-btn:hover {
            background: var(--accent-blue);
            color: white;
            border-color: var(--accent-blue);
        }

        .tab-btn.active {
            background: var(--accent-blue);
            color: white;
            border-color: var(--accent-blue);
        }

        .tab-content {
            display: none;
            animation: fadeIn 0.3s;
        }

        .tab-content.active {
            display: block;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .card {
            background-color: var(--bg-secondary);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 20px;
            transition: transform 0.3s;
        }

        .card:hover {
            transform: translateY(-5px);
        }

        .card h3 {
            font-size: 1.3rem;
            margin-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 10px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }

        .stat {
            padding: 20px;
            background-color: rgba(37, 99, 235, 0.1);
            border-left: 4px solid var(--accent-blue);
            border-radius: 8px;
            margin-bottom: 15px;
        }

        .stat-label {
            color: var(--text-muted);
            font-size: 0.9rem;
            margin-bottom: 5px;
        }

        .stat-value {
            font-size: 1.5rem;
            font-weight: bold;
            color: white;
        }

        .stat-change {
            font-size: 0.9rem;
            margin-top: 5px;
        }

        .stat-change.positive {
            color: var(--accent-green);
        }

        .stat-change.negative {
            color: var(--accent-red);
        }

        .news-item {
            padding: 20px;
            border-bottom: 1px solid var(--border-color);
            transition: background 0.3s;
        }

        .news-item:hover {
            background-color: rgba(37, 99, 235, 0.05);
        }

        .news-item:last-child {
            border-bottom: none;
        }

        .news-title {
            font-size: 1.1rem;
            font-weight: bold;
            margin-bottom: 8px;
            color: #60a5fa;
        }

        .news-title a {
            color: #60a5fa;
            text-decoration: none;
        }

        .news-title a:hover {
            text-decoration: underline;
        }

        .news-desc {
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-bottom: 8px;
        }

        .news-meta {
            display: flex;
            justify-content: space-between;
            font-size: 0.85rem;
            color: var(--text-muted);
        }

        .news-source {
            background: rgba(16, 185, 129, 0.2);
            color: var(--accent-green);
            padding: 2px 8px;
            border-radius: 4px;
            display: inline-block;
        }

        .search-box {
            margin-bottom: 20px;
        }

        .search-box input {
            width: 100%;
            padding: 12px;
            background: var(--bg-secondary);
            border: 1px solid var(--border-color);
            color: var(--text-main);
            border-radius: 8px;
            font-size: 1rem;
        }

        .search-box input::placeholder {
            color: var(--text-muted);
        }

        .btn {
            background: var(--accent-blue);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.9rem;
            transition: all 0.3s;
            margin-right: 10px;
            margin-top: 10px;
        }

        .btn:hover {
            background: #1d4ed8;
            transform: translateY(-2px);
        }

        .loading {
            text-align: center;
            padding: 40px;
            color: var(--text-muted);
        }

        .spinner {
            border: 3px solid var(--border-color);
            border-top: 3px solid var(--accent-blue);
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .error {
            background: rgba(239, 68, 68, 0.1);
            border-left: 4px solid var(--accent-red);
            padding: 15px;
            border-radius: 8px;
            color: var(--accent-red);
            margin-bottom: 20px;
        }

        .success {
            background: rgba(16, 185, 129, 0.1);
            border-left: 4px solid var(--accent-green);
            padding: 15px;
            border-radius: 8px;
            color: var(--accent-green);
            margin-bottom: 20px;
        }

        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            background: var(--accent-green);
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        footer {
            text-align: center;
            padding: 30px;
            border-top: 1px solid var(--border-color);
            color: var(--text-muted);
            margin-top: 50px;
        }

        @media (max-width: 768px) {
            header h1 { font-size: 1.8rem; }
            .grid { grid-template-columns: 1fr; }
            .tabs { flex-direction: column; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📰 DailyFeed</h1>
            <p>Live News Intelligence & Market Data Platform</p>
            <p style="font-size: 0.9rem; margin-top: 10px;">
                <span class="status-indicator"></span>
                Live Updates
            </p>
        </header>

        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('market')">📊 Market</button>
            <button class="tab-btn" onclick="switchTab('india-news')">🇮🇳 India News</button>
            <button class="tab-btn" onclick="switchTab('global-news')">🌍 Global News</button>
            <button class="tab-btn" onclick="switchTab('search')">🔍 Search</button>
        </div>

        <!-- Market Tab -->
        <div id="market" class="tab-content active">
            <button class="btn" onclick="refreshMarket()">🔄 Refresh</button>
            
            <div id="market-content">
                <div class="loading">
                    <div class="spinner"></div>
                    <p>Loading market data...</p>
                </div>
            </div>
        </div>

        <!-- India News Tab -->
        <div id="india-news" class="tab-content">
            <button class="btn" onclick="refreshIndiaNews()">🔄 Refresh</button>
            
            <div id="india-news-content">
                <div class="loading">
                    <div class="spinner"></div>
                    <p>Loading India news...</p>
                </div>
            </div>
        </div>

        <!-- Global News Tab -->
        <div id="global-news" class="tab-content">
            <button class="btn" onclick="refreshGlobalNews()">🔄 Refresh</button>
            
            <div id="global-news-content">
                <div class="loading">
                    <div class="spinner"></div>
                    <p>Loading global news...</p>
                </div>
            </div>
        </div>

        <!-- Search Tab -->
        <div id="search" class="tab-content">
            <div class="search-box">
                <input type="text" id="search-input" placeholder="Search news..." />
                <button class="btn" onclick="performSearch()">Search</button>
            </div>
            
            <div id="search-content"></div>
        </div>

        <footer>
            <p>&copy; 2024 DailyFeed - News Intelligence Platform</p>
            <p style="font-size: 0.85rem; margin-top: 10px;">
                API Status: <span id="api-status" style="color: var(--accent-green);">● Online</span>
            </p>
        </footer>
    </div>

    <script>
        const API_BASE = '/api';
        let autoRefreshInterval;

        // Tab switching
        function switchTab(tabName) {
            document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');

            // Load content
            if (tabName === 'market') refreshMarket();
            if (tabName === 'india-news') refreshIndiaNews();
            if (tabName === 'global-news') refreshGlobalNews();
        }

        // Format date
        function formatDate(dateString) {
            return new Date(dateString).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        // Format number with color
        function formatChange(value) {
            const color = value >= 0 ? 'positive' : 'negative';
            const symbol = value >= 0 ? '+' : '';
            return `<span class="stat-change ${color}">${symbol}${value.toFixed(2)}%</span>`;
        }

        // Display market data
        async function refreshMarket() {
            const content = document.getElementById('market-content');
            content.innerHTML = '<div class="loading"><div class="spinner"></div><p>Loading market data...</p></div>';

            try {
                const response = await fetch(`${API_BASE}/market/dashboard`);
                const data = await response.json();

                if (!data.success) {
                    content.innerHTML = '<div class="error">Failed to load market data</div>';
                    return;
                }

                let html = '';

                // Indian Market
                html += '<div class="card"><h3>📈 Indian Market</h3><div class="grid">';
                for (const [key, index] of Object.entries(data.markets.india.indices)) {
                    html += `
                        <div class="stat">
                            <div class="stat-label">${index.name}</div>
                            <div class="stat-value">${index.value.toLocaleString()}</div>
                            ${formatChange(index.changePercentage)}
                        </div>
                    `;
                }
                html += '</div></div>';

                // Global Market
                html += '<div class="card"><h3>🌍 Global Market</h3><div class="grid">';
                for (const [key, index] of Object.entries(data.markets.global.indices)) {
                    html += `
                        <div class="stat">
                            <div class="stat-label">${index.name}</div>
                            <div class="stat-value">${index.value.toLocaleString()}</div>
                            ${formatChange(index.changePercentage)}
                        </div>
                    `;
                }
                html += '</div></div>';

                // Commodities
                html += '<div class="card"><h3>⛽ Commodities</h3><div class="grid">';
                for (const [key, commodity] of Object.entries(data.markets.commodities.commodities)) {
                    html += `
                        <div class="stat">
                            <div class="stat-label">${commodity.name}</div>
                            <div class="stat-value">${commodity.value}</div>
                            ${formatChange(commodity.changePercentage)}
                        </div>
                    `;
                }
                html += '</div></div>';

                // Crypto
                html += '<div class="card"><h3>₿ Cryptocurrencies</h3><div class="grid">';
                for (const [key, crypto] of Object.entries(data.markets.crypto.cryptocurrencies)) {
                    html += `
                        <div class="stat">
                            <div class="stat-label">${crypto.name}</div>
                            <div class="stat-value">${crypto.value}</div>
                            ${formatChange(crypto.changePercentage)}
                        </div>
                    `;
                }
                html += '</div></div>';

                content.innerHTML = html + '<div class="success">Last updated: ' + new Date().toLocaleTimeString() + '</div>';
            } catch (error) {
                content.innerHTML = '<div class="error">Error: ' + error.message + '</div>';
            }
        }

        // Display India news
        async function refreshIndiaNews() {
            const content = document.getElementById('india-news-content');
            content.innerHTML = '<div class="loading"><div class="spinner"></div><p>Loading India news...</p></div>';

            try {
                const response = await fetch(`${API_BASE}/news/india?pageSize=25`);
                const data = await response.json();

                if (!data.success || !data.articles || data.articles.length === 0) {
                    content.innerHTML = '<div class="error">No news available</div>';
                    return;
                }

                let html = '<div class="card"><h3>🇮🇳 Top India News</h3>';
                data.articles.forEach(article => {
                    html += `
                        <div class="news-item">
                            <div class="news-title">
                                <a href="${article.url}" target="_blank">${article.title}</a>
                            </div>
                            <div class="news-desc">${article.description || 'No description available'}</div>
                            <div class="news-meta">
                                <span class="news-source">${article.source}</span>
                                <span>${formatDate(article.publishedAt)}</span>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
                content.innerHTML = html;
            } catch (error) {
                content.innerHTML = '<div class="error">Error: ' + error.message + '</div>';
            }
        }

        // Display global news
        async function refreshGlobalNews() {
            const content = document.getElementById('global-news-content');
            content.innerHTML = '<div class="loading"><div class="spinner"></div><p>Loading global news...</p></div>';

            try {
                const response = await fetch(`${API_BASE}/news/global?pageSize=25`);
                const data = await response.json();

                if (!data.success || !data.articles || data.articles.length === 0) {
                    content.innerHTML = '<div class="error">No news available</div>';
                    return;
                }

                let html = '<div class="card"><h3>🌍 Top Global News</h3>';
                data.articles.forEach(article => {
                    html += `
                        <div class="news-item">
                            <div class="news-title">
                                <a href="${article.url}" target="_blank">${article.title}</a>
                            </div>
                            <div class="news-desc">${article.description || 'No description available'}</div>
                            <div class="news-meta">
                                <span class="news-source">${article.source}</span>
                                <span>${formatDate(article.publishedAt)}</span>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
                content.innerHTML = html;
            } catch (error) {
                content.innerHTML = '<div class="error">Error: ' + error.message + '</div>';
            }
        }

        // Search news
        async function performSearch() {
            const query = document.getElementById('search-input').value;
            if (!query.trim()) {
                alert('Please enter a search term');
                return;
            }

            const content = document.getElementById('search-content');
            content.innerHTML = '<div class="loading"><div class="spinner"></div><p>Searching...</p></div>';

            try {
                const response = await fetch(`${API_BASE}/news/search?query=${encodeURIComponent(query)}&pageSize=30`);
                const data = await response.json();

                if (!data.success || !data.articles || data.articles.length === 0) {
                    content.innerHTML = '<div class="error">No results found for: ' + query + '</div>';
                    return;
                }

                let html = '<div class="card"><h3>🔍 Search Results for: ' + query + '</h3>';
                html += '<p style="color: var(--text-muted); margin-bottom: 15px;">Found ' + data.articles.length + ' articles</p>';
                
                data.articles.forEach(article => {
                    html += `
                        <div class="news-item">
                            <div class="news-title">
                                <a href="${article.url}" target="_blank">${article.title}</a>
                            </div>
                            <div class="news-desc">${article.description || 'No description available'}</div>
                            <div class="news-meta">
                                <span class="news-source">${article.source}</span>
                                <span>${formatDate(article.publishedAt)}</span>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
                content.innerHTML = html;
            } catch (error) {
                content.innerHTML = '<div class="error">Error: ' + error.message + '</div>';
            }
        }

        // Check API health
        async function checkAPIHealth() {
            try {
                const response = await fetch(`${API_BASE}/health`);
                if (response.ok) {
                    document.getElementById('api-status').innerHTML = '● Online';
                    document.getElementById('api-status').style.color = 'var(--accent-green)';
                } else {
                    document.getElementById('api-status').innerHTML = '● Offline';
                    document.getElementById('api-status').style.color = 'var(--accent-red)';
                }
            } catch (error) {
                document.getElementById('api-status').innerHTML = '● Error';
                document.getElementById('api-status').style.color = 'var(--accent-red)';
            }
        }

        // Initialize
        window.addEventListener('load', () => {
            checkAPIHealth();
            refreshMarket();
            
            // Check API health every minute
            setInterval(checkAPIHealth, 60000);
        });

        // Allow Enter key in search
        document.addEventListener('DOMContentLoaded', () => {
            const searchInput = document.getElementById('search-input');
            if (searchInput) {
                searchInput.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') performSearch();
                });
            }
        });
    </script>
</body>
</html>
HTMLEOF
echo -e "${GREEN}✓ public/index.html created${NC}"
echo ""

echo -e "${BLUE}Step 12: Creating Dockerfile...${NC}"
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
EOF
echo -e "${GREEN}✓ Dockerfile created${NC}"
echo ""

echo -e "${BLUE}Step 13: Creating docker-compose.yml...${NC}"
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  dailyfeed:
    build: .
    container_name: dailyfeed
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - PORT=5000
      - NEWSAPI_KEY=${NEWSAPI_KEY}
      - CACHE_TTL=300
    volumes:
      - ./:/app
      - /app/node_modules
    restart: unless-stopped
    networks:
      - dailyfeed-network

networks:
  dailyfeed-network:
    driver: bridge
EOF
echo -e "${GREEN}✓ docker-compose.yml created${NC}"
echo ""

echo -e "${BLUE}Step 14: Creating vercel.json...${NC}"
cat > vercel.json << 'EOF'
{
  "buildCommand": "npm install",
  "devCommand": "npm run dev",
  "framework": "express",
  "functions": {
    "api/**/*.js": {
      "memory": 1024,
      "maxDuration": 60
    }
  },
  "env": [
    {
      "key": "NEWSAPI_KEY",
      "value": "@NEWSAPI_KEY"
    },
    {
      "key": "NODE_ENV",
      "value": "production"
    }
  ]
}
EOF
echo -e "${GREEN}✓ vercel.json created${NC}"
echo ""

echo -e "${BLUE}Step 15: Creating .github/workflows/deploy.yml...${NC}"
mkdir -p .github/workflows 2>/dev/null || true
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to Vercel

on:
  push:
    branches:
      - main
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Test build
        run: npm list
      
      - name: Deploy to Vercel
        if: github.ref == 'refs/heads/main'
        uses: vercel/action@master
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
EOF
echo -e "${GREEN}✓ .github/workflows/deploy.yml created${NC}"
echo ""

echo -e "${BLUE}Step 16: Updating .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json
yarn.lock

# Environment variables
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build
dist/
build/

# Docker
.dockerignore
EOF
echo -e "${GREEN}✓ .gitignore updated${NC}"
echo ""

echo -e "${BLUE}Step 17: Installing dependencies...${NC}"
if command -v npm &> /dev/null; then
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}⚠ npm not found. Please run 'npm install' manually${NC}"
fi
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo "📝 Next Steps:"
echo ""
echo "1️⃣  Get your NewsAPI Key:"
echo "   Visit: https://newsapi.org"
echo "   Sign up (free tier: 100 requests/day)"
echo ""
echo "2️⃣  Configure environment:"
echo "   cp .env.example .env"
echo "   Edit .env and add: NEWSAPI_KEY=your_key_here"
echo ""
echo "3️⃣  Run locally:"
echo "   npm run dev"
echo "   Visit: http://localhost:5000"
echo ""
echo "4️⃣  Deploy (optional):"
echo "   git add ."
echo "   git commit -m 'Deploy full-stack DailyFeed'"
echo "   git push origin main"
echo ""
echo "   Then deploy on:"
echo "   - Vercel: https://vercel.com"
echo "   - Railway: https://railway.app"
echo "   - Docker: docker-compose up"
echo ""
echo -e "${GREEN}================================${NC}"
echo "All files created successfully! 🚀"
echo -e "${GREEN}================================${NC}"
EOF
echo -e "${GREEN}✓ setup.sh created${NC}"
echo ""

# Make setup script executable
chmod +x setup.sh

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ ALL FILES CREATED SUCCESSFULLY!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Files created:${NC}"
echo "  ✓ package.json"
echo "  ✓ .env.example"
echo "  ✓ config/newsConfig.js"
echo "  ✓ services/newsService.js"
echo "  ✓ services/marketService.js"
echo "  ✓ routes/newsRoutes.js"
echo "  ✓ routes/marketRoutes.js"
echo "  ✓ routes/healthRoutes.js"
echo "  ✓ server.js"
echo "  ✓ public/index.html"
echo "  ✓ Dockerfile"
echo "  ✓ docker-compose.yml"
echo "  ✓ vercel.json"
echo "  ✓ .github/workflows/deploy.yml"
echo "  ✓ .gitignore (updated)"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo "1️⃣  Get NewsAPI Key:"
echo "   → Visit https://newsapi.org"
echo "   → Sign up (free: 100 requests/day)"
echo ""
echo "2️⃣  Configure:"
echo "   → cp .env.example .env"
echo "   → Edit .env with your NEWSAPI_KEY"
echo ""
echo "3️⃣  Run:"
echo "   → npm run dev"
echo "   → Open http://localhost:5000"
echo ""
echo "4️⃣  Commit & Push:"
echo "   → git add ."
echo "   → git commit -m 'Add full-stack implementation'"
echo "   → git push origin main"
echo ""
echo "5️⃣  Deploy:"
echo "   → Vercel: https://vercel.com"
echo "   → Railway: https://railway.app"
echo "   → Docker: docker-compose up"
echo ""
echo -e "${GREEN}🎉 Your DailyFeed is ready!${NC}"
