// News Configuration with NewsAPI and RSS feeds

const newsConfig = {
  // NewsAPI Configuration
  newsapi: {
    baseUrl: process.env.NEWSAPI_BASE_URL || 'https://newsapi.org',
    apiKey: 02032547366e4ca5b9479b817c68dbcd,
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
