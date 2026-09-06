import yfinance as yf
import pandas as pd
import numpy as np
from pathlib import Path

tickers = [
    "AAPL", "MSFT", "GOOGL", "NVDA", "CRM",
    "JPM", "BAC", "WFC", "GS", "MS",
    "JNJ", "PFE", "UNH", "ABBV", "MRK",
    "XOM", "CVX", "COP", "SLB", "EOG",
    "AMZN", "TSLA", "HD", "MCD", "NKE",
    "BA", "CAT", "GE", "HON", "UPS",
    "META", "NFLX", "DIS", "VZ", "T",
    "NEE", "DUK", "SO", "D", "AEP",
    "PG", "KO", "PEP", "WMT", "COST"
]

# Add S&P 500 for beta calculation
market_ticker = "^GSPC"

start_date = "2023-01-01"
end_date = pd.Timestamp.today().strftime("%Y-%m-%d")

# Download data for all tickers + market index

print("Downloading market data ...")
all_tickers = tickers + [market_ticker]
data = yf.download(all_tickers, start=start_date, end=end_date, group_by="ticker", auto_adjust=True, progress=False)

# Extract and save raw daily OHLCV
raw_frames = []
for ticker in tickers:
    df = data[ticker].copy()
    df["Ticker"] = ticker
    df = df.reset_index()
    df = df.rename(columns={
        "Date": "Date",
        "Open": "Open",
        "High": "High",
        "Low": "Low",
        "Close": "Close",
        "Volume": "Volume"
    })
    raw_frames.append(df)

raw_df = pd.concat(raw_frames, ignore_index=True)
raw_file = "data/raw/market_data_raw.csv"
raw_df.to_csv(raw_file, index=False)
print(f"Raw market data saved to {raw_file}")


# Compute daily returns for each ticker and the market
returns_dict = {}
for ticker in all_tickers:
    close = data[ticker]["Close"]
    returns = close.pct_change().dropna()
    returns_dict[ticker] = returns

# Market returns
market_returns = returns_dict[market_ticker]
market_var = market_returns.var()

# For each company, compute metrics
rows = []
for ticker in tickers:
    close = data[ticker]["Close"]
    volume = data[ticker]["Volume"]
    ret = returns_dict[ticker]

    latest_price = close.iloc[-1]
    avg_volume = volume.mean()
    total_return = (close.iloc[-1] / close.iloc[0]) - 1
    volatility = ret.std() * np.sqrt(252)   # annualized
    # Beta = Cov(ret, market_ret) / Var(market_ret)
    cov = np.cov(ret, market_returns)[0, 1]
    beta = cov / market_var

    rows.append({
        "ticker": ticker,
        "latest_price": latest_price,
        "avg_volume": avg_volume,
        "total_return": total_return,
        "volatility": volatility,
        "beta": beta
    })

clean_df = pd.DataFrame(rows)

# Merge with company info from financial clean dataset to add sector
financial_clean = pd.read_csv("data/clean/company_financials_clean.csv")
company_info = financial_clean[["ticker", "company", "sector"]].drop_duplicates()
clean_df = clean_df.merge(company_info, on="ticker", how="left")

# Reorder columns
clean_df = clean_df[["ticker", "company", "sector", "latest_price", "avg_volume", "total_return", "volatility", "beta"]]

clean_file = "data/clean/market_data_clean.csv"
clean_df.to_csv(clean_file, index=False)
print(f"Clean market data saved to {clean_file}")
print("\nDone.")