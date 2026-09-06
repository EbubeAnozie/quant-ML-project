# Generate preview images for market data
library(readr)
library(dplyr)
library(gt)

# ------------------------------------------------------------
# Raw data preview (first 10 rows for a few tickers)
# ------------------------------------------------------------
raw <- read_csv("data/raw/market_data_raw.csv", show_col_types = FALSE)

raw_preview <- raw %>%
  filter(Ticker %in% c("AAPL", "MSFT", "GOOGL")) %>%
  head(10) %>%
  select(Date, Ticker, Open, High, Low, Close, Volume)

gt_raw <- raw_preview %>%
  gt() %>%
  tab_header(title = "Raw Market Data (Sample)") %>%
  fmt_number(columns = where(is.numeric), decimals = 2) %>%
  fmt_date(columns = Date, date_style = "iso") %>%
  cols_label(
    Date = "Date",
    Ticker = "Ticker",
    Open = "Open (USD)",
    High = "High (USD)",
    Low = "Low (USD)",
    Close = "Close (USD)",
    Volume = "Volume"
  ) %>%
  tab_options(table.font.size = "small", data_row.padding = px(3))

gtsave(gt_raw, "market_raw_preview.png", expand = 10)

# ------------------------------------------------------------
# Clean data preview (first 10 rows of metrics)
# ------------------------------------------------------------
clean <- read_csv("data/clean/market_data_clean.csv", show_col_types = FALSE)

clean_preview <- clean %>%
  head(10) %>%
  select(ticker, company, sector, latest_price, avg_volume, total_return, volatility, beta)

gt_clean <- clean_preview %>%
  gt() %>%
  tab_header(title = "Clean Market Data (First 10 Companies)") %>%
  fmt_currency(columns = c(latest_price), currency = "USD", decimals = 2) %>%
  fmt_number(columns = c(avg_volume), decimals = 0, suffix = " shares") %>%
  fmt_percent(columns = c(total_return), decimals = 2) %>%
  fmt_number(columns = c(volatility, beta), decimals = 3) %>%
  cols_label(
    ticker = "Ticker",
    company = "Company",
    sector = "Sector",
    latest_price = "Latest Price",
    avg_volume = "Avg Volume",
    total_return = "Total Return",
    volatility = "Volatility",
    beta = "Beta"
  ) %>%
  tab_options(table.font.size = "small", data_row.padding = px(3))

gtsave(gt_clean, "market_clean_preview.png", expand = 10)