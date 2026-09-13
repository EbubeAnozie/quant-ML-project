# ------------------------------------------------------------------
# Generate all preview images (financial + market) with consistent style
# ------------------------------------------------------------------
library(readr)
library(dplyr)
library(tidyr)
library(gt)

# ------------------------------------------------------------------
# Shared style function: apply to every gt table
# ------------------------------------------------------------------
style_table <- function(gt_obj) {
  gt_obj %>%
    tab_options(
      table.font.size          = px(13),      # same font size everywhere
      table.font.name          = "Helvetica", # consistent font
      heading.title.font.size  = px(16),      # title size
      heading.title.font.weight = "bold",
      column_labels.font.weight = "bold",
      column_labels.font.size   = px(13),
      data_row.padding          = px(4),
      row.striping.include_table_body = TRUE,
      table.border.top.color    = "lightgray",
      table.border.bottom.color = "lightgray"
    )
}

# ------------------------------------------------------------------
# 1. RAW FINANCIAL PREVIEW
# ------------------------------------------------------------------
raw <- read_csv("data/raw/company_financials_raw.csv", show_col_types = FALSE)

raw_preview <- raw %>%
  slice_head(n = 10) %>%
  select(ticker, company, fiscal_year, Revenue, NetIncome,
         TotalLiabilities, LongTermDebt, TotalAssets, TotalEquity) %>%
  mutate(across(c(Revenue, NetIncome, TotalLiabilities, LongTermDebt,
                  TotalAssets, TotalEquity), ~ .x / 1e9))

gt_raw <- raw_preview %>%
  gt() %>%
  tab_header(title = "Raw Financial Data (First 10 Rows)") %>%
  fmt_number(columns = c(Revenue, NetIncome, TotalLiabilities,
                         LongTermDebt, TotalAssets, TotalEquity),
             decimals = 2, pattern = "${x}B") %>%
  cols_label(
    ticker = "Ticker", company = "Company", fiscal_year = "FY",
    Revenue = "Revenue", NetIncome = "Net Income",
    TotalLiabilities = "Total Liabilities", LongTermDebt = "Long Term Debt",
    TotalAssets = "Total Assets", TotalEquity = "Total Equity"
  ) %>%
  style_table()

gtsave(gt_raw, "raw_preview.png", expand = 10, vwidth = 1400)

# ------------------------------------------------------------------
# 2. CLEAN FINANCIAL PREVIEW
# ------------------------------------------------------------------
clean <- read_csv("data/clean/company_financials_clean.csv", show_col_types = FALSE)

clean_preview <- clean %>%
  slice_head(n = 10) %>%
  select(ticker, company, sector, Revenue, NetIncome,
         TotalLiabilities, LongTermDebt, ROA, ROE, Debt_to_Equity) %>%
  mutate(across(c(Revenue, NetIncome, TotalLiabilities, LongTermDebt),
                ~ .x / 1e9))

gt_clean <- clean_preview %>%
  gt() %>%
  tab_header(title = "Clean Financial Data (First 10 Rows)") %>%
  fmt_number(columns = c(Revenue, NetIncome, TotalLiabilities, LongTermDebt),
             decimals = 2, pattern = "${x}B") %>%
  fmt_number(columns = c(ROA, ROE, Debt_to_Equity), decimals = 3) %>%
  cols_label(
    ticker = "Ticker", company = "Company", sector = "Sector",
    Revenue = "Revenue", NetIncome = "Net Income",
    TotalLiabilities = "Total Liabilities", LongTermDebt = "Long Term Debt",
    ROA = "ROA", ROE = "ROE", Debt_to_Equity = "Debt/Equity"
  ) %>%
  style_table()

gtsave(gt_clean, "clean_preview.png", expand = 10, vwidth = 1400)

# ------------------------------------------------------------------
# 3. SUMMARY STATISTICS PREVIEW
# ------------------------------------------------------------------
summary_stats <- clean %>%
  select(Revenue, NetIncome, TotalAssets, ROA, ROE,
         Debt_to_Equity, Profit_Margin) %>%
  mutate(across(c(Revenue, NetIncome, TotalAssets), ~ .x / 1e9)) %>%
  summarise(across(everything(),
                   list(
                     Min    = ~min(.x, na.rm = TRUE),
                     Q1     = ~quantile(.x, 0.25, na.rm = TRUE),
                     Median = ~median(.x, na.rm = TRUE),
                     Mean   = ~mean(.x, na.rm = TRUE),
                     Q3     = ~quantile(.x, 0.75, na.rm = TRUE),
                     Max    = ~max(.x, na.rm = TRUE),
                     SD     = ~sd(.x, na.rm = TRUE)
                   ))) %>%
  pivot_longer(cols = everything(), names_to = "Statistic", values_to = "Value") %>%
  separate(Statistic, into = c("Variable", "Stat"), sep = "_(?=[^_]+$)") %>%
  pivot_wider(names_from = Stat, values_from = Value) %>%
  select(Variable, Min, Q1, Median, Mean, Q3, Max, SD)

gt_summary <- summary_stats %>%
  gt() %>%
  tab_header(title = "Summary Statistics for Financial Variables") %>%
  fmt_number(columns = where(is.numeric), decimals = 3) %>%
  cols_label(Variable = "Variable") %>%
  style_table()

gtsave(gt_summary, "summary_stats.png", expand = 10, vwidth = 1200)