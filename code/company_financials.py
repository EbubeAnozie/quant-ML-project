import requests
import pandas as pd
import time
import os
from pathlib import Path


HEADERS = {
    "User-Agent": "Ebube Anozie ebube.anozie@colorado.edu"
}

# Get company ticker mapping from SEC

print("Fetching company ticker mapping from SEC ...")
ticker_url = "https://www.sec.gov/files/company_tickers.json"
resp = requests.get(ticker_url, headers=HEADERS)
resp.raise_for_status()
ticker_data = resp.json()

# Convert to DataFrame: columns = cik, ticker, title
ticker_df = pd.DataFrame.from_dict(ticker_data, orient="index")
ticker_df["cik"] = ticker_df["cik_str"].astype(str).str.zfill(10)
ticker_df = ticker_df[["ticker", "cik", "title"]]
print(f"Loaded {len(ticker_df)} companies from SEC.")


selected_tickers = [
    # Technology
    "AAPL", "MSFT", "GOOGL", "NVDA", "CRM",
    # Financials
    "JPM", "BAC", "WFC", "GS", "MS",
    # Healthcare
    "JNJ", "PFE", "UNH", "ABBV", "MRK",
    # Energy
    "XOM", "CVX", "COP", "SLB", "EOG",
    # Consumer Discretionary
    "AMZN", "TSLA", "HD", "MCD", "NKE",
    # Industrials
    "BA", "CAT", "GE", "HON", "UPS",
    # Communication Services
    "META", "NFLX", "DIS", "VZ", "T",
    # Utilities
    "NEE", "DUK", "SO", "D", "AEP",
    # Consumer Staples
    "PG", "KO", "PEP", "WMT", "COST"
]

# Get rows for selected tickers
selected_df = ticker_df[ticker_df["ticker"].isin(selected_tickers)].copy()
print(f"Selected {len(selected_df)} companies.")


# Extract concepts
concept_tags = {
    "Revenue": [
        "RevenueFromContractWithCustomerExcludingInterest",
        "Revenues",
        "SalesRevenueNet",
        "RevenueFromContractWithCustomerIncludingAssessedTax"
    ],
    "NetIncome": [
        "NetIncomeLoss",
        "ProfitLoss"
    ],
    "TotalAssets": ["Assets"],
    "TotalLiabilities": ["Liabilities"],
    "TotalEquity": [
        "StockholdersEquity",
        "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest"
    ],
    "LongTermDebt": [
        "LongTermDebtNoncurrent",
        "LongTermDebt"
    ],
    "OperatingIncome": ["OperatingIncomeLoss"],
    "CashFromOperations": ["NetCashProvidedByUsedInOperatingActivities"]
}

# Build raw data

raw_rows = []

for idx, row in selected_df.iterrows():
    ticker = row["ticker"]
    cik = row["cik"]
    company_name = row["title"]
    print(f"Processing {ticker} ({company_name}) ...")

    # SEC CompanyFacts endpoint
    facts_url = f"https://data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json"
    try:
        r = requests.get(facts_url, headers=HEADERS)
        r.raise_for_status()
        facts = r.json()
    except Exception as e:
        print(f"  Error fetching data for {ticker}: {e}")
        continue

    # Extract facts from 'us-gaap'
    us_gaap = facts.get("facts", {}).get("us-gaap", {})
    if not us_gaap:
        print(f"  No us-gaap facts found for {ticker}")
        continue

    
    # Take the most recent 10-K filing (latest fiscal year).

    annual_periods = []
    if "RevenueFromContractWithCustomerExcludingInterest" in us_gaap:
        rev_data = us_gaap["RevenueFromContractWithCustomerExcludingInterest"]
        units = rev_data.get("units", {})
        if "USD" in units:
            annual_periods = [item for item in units["USD"] if item.get("form") == "10-K"]
    elif "Revenues" in us_gaap:  # fallback if new tag not present
        rev_data = us_gaap["Revenues"]
        units = rev_data.get("units", {})
        if "USD" in units:
            annual_periods = [item for item in units["USD"] if item.get("form") == "10-K"]

    if not annual_periods:
        print(f"  No 10-K annual revenue data for {ticker}")
        continue

    # Sort by fiscal year descending and take the most recent
    annual_periods.sort(key=lambda x: x.get("end", ""), reverse=True)
    latest = annual_periods[0]
    latest_fy = latest.get("fy")
    latest_end = latest.get("end")

    # Extract each concept for that fiscal year
    row_data = {
        "ticker": ticker,
        "company": company_name,
        "cik": cik,
        "fiscal_year": latest_fy,
        "fiscal_year_end": latest_end
    }

    for col_name, tag_list in concept_tags.items():
        val = None
        for tag in tag_list:
            if tag in us_gaap:
                units = us_gaap[tag].get("units", {})
                if "USD" in units:
                    for item in units["USD"]:
                        if item.get("fy") == latest_fy and item.get("form") == "10-K":
                            val = item.get("val")
                            break
                if val is not None:
                    break
        row_data[col_name] = val

    raw_rows.append(row_data)
    time.sleep(0.1)

# Create raw DataFrame
raw_df = pd.DataFrame(raw_rows)
raw_file = "data/raw/company_financials_raw.csv"
raw_df.to_csv(raw_file, index=False)
print(f"\nRaw data saved to {raw_file}")



# 6. CLEAN AND COMPUTE DERIVED METRICS

clean_df = raw_df.copy()

# Convert numeric columns to float
numeric_cols = list(concept_tags.keys())
for col in numeric_cols:
    clean_df[col] = pd.to_numeric(clean_df[col], errors="coerce")

# Compute ratios
clean_df["ROA"] = clean_df["NetIncome"] / clean_df["TotalAssets"]
clean_df["ROE"] = clean_df["NetIncome"] / clean_df["TotalEquity"]
clean_df["Debt_to_Equity"] = clean_df["LongTermDebt"] / clean_df["TotalEquity"]
clean_df["Profit_Margin"] = clean_df["NetIncome"] / clean_df["Revenue"]

# Add a sector column
sector_map = {
    "AAPL": "Technology", "MSFT": "Technology", "GOOGL": "Technology", "NVDA": "Technology", "CRM": "Technology",
    "JPM": "Financials", "BAC": "Financials", "WFC": "Financials", "GS": "Financials", "MS": "Financials",
    "JNJ": "Healthcare", "PFE": "Healthcare", "UNH": "Healthcare", "ABBV": "Healthcare", "MRK": "Healthcare",
    "XOM": "Energy", "CVX": "Energy", "COP": "Energy", "SLB": "Energy", "EOG": "Energy",
    "AMZN": "Consumer Discretionary", "TSLA": "Consumer Discretionary", "HD": "Consumer Discretionary",
    "MCD": "Consumer Discretionary", "NKE": "Consumer Discretionary",
    "BA": "Industrials", "CAT": "Industrials", "GE": "Industrials", "HON": "Industrials", "UPS": "Industrials",
    "META": "Communication Services", "NFLX": "Communication Services", "DIS": "Communication Services",
    "VZ": "Communication Services", "T": "Communication Services",
    "NEE": "Utilities", "DUK": "Utilities", "SO": "Utilities", "D": "Utilities", "AEP": "Utilities",
    "PG": "Consumer Staples", "KO": "Consumer Staples", "PEP": "Consumer Staples", "WMT": "Consumer Staples",
    "COST": "Consumer Staples"
}
clean_df["sector"] = clean_df["ticker"].map(sector_map)

# Reorder columns for clarity
final_cols = [
    "ticker", "company", "sector", "fiscal_year", "fiscal_year_end",
    "Revenue", "NetIncome", "TotalAssets", "TotalLiabilities", "TotalEquity",
    "LongTermDebt", "OperatingIncome", "CashFromOperations",
    "ROA", "ROE", "Debt_to_Equity", "Profit_Margin"
]
clean_df = clean_df[final_cols]

# Save clean dataset
clean_file = "data/clean/company_financials_clean.csv"
clean_df.to_csv(clean_file, index=False)
print(f"Clean data saved to {clean_file}")

print("\nDone. Preview of clean data:")
print(clean_df.head())