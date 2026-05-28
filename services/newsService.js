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
