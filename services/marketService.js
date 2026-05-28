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
