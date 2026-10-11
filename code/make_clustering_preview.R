library(readr)
library(dplyr)
library(gt)

fin    <- read_csv("data/clean/company_financials_clean.csv", show_col_types = FALSE)
market <- read_csv("data/clean/market_data_clean.csv",        show_col_types = FALSE)

merged <- inner_join(fin, market, by = c("ticker", "company", "sector"))

clust_vars <- c(
  "Revenue","NetIncome","TotalAssets","TotalLiabilities","TotalEquity",
  "LongTermDebt","OperatingIncome","CashFromOperations",
  "ROA","ROE","Debt_to_Equity","Profit_Margin",
  "latest_price","avg_volume","total_return","volatility","beta"
)

clust_df <- merged %>% select(ticker, all_of(clust_vars)) %>% na.omit()
clust_ids <- clust_df$ticker
X <- scale(clust_df %>% select(-ticker))

preview_df <- as.data.frame(round(X[1:10, 1:6], 3)) %>%
  mutate(ticker = clust_ids[1:10], .before = 1)

preview_df %>%
  gt() %>%
  tab_header(title = "Clustering Input (First 10 Companies, First 6 Standardized Features)") %>%
  tab_options(table.font.size = "small", data_row.padding = px(3)) %>%
  gtsave("img_clustering_sample.png", expand = 10)