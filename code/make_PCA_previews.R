library(readr)
library(dplyr)
library(gt)
library(ggplot2)

# --- 1. Sample of the standardized PCA input data ---
fin    <- read_csv("data/clean/company_financials_clean.csv", show_col_types = FALSE)
market <- read_csv("data/clean/market_data_clean.csv",        show_col_types = FALSE)

merged <- inner_join(fin, market, by = c("ticker", "company", "sector"))

pca_vars <- c(
  "Revenue","NetIncome","TotalAssets","TotalLiabilities","TotalEquity",
  "LongTermDebt","OperatingIncome","CashFromOperations",
  "ROA","ROE","Debt_to_Equity","Profit_Margin",
  "latest_price","avg_volume","total_return","volatility","beta"
)

pca_df  <- merged %>% select(ticker, all_of(pca_vars)) %>% na.omit()
pca_ids <- pca_df$ticker
X       <- scale(pca_df %>% select(-ticker))

# Save the standardized data for the website link
write_csv(as.data.frame(X) %>% mutate(ticker = pca_ids, .before = 1),
          "data/clean/pca_data.csv")

# Image of the sample
preview_df <- as.data.frame(round(X[1:10, 1:6], 3)) %>%
  mutate(ticker = pca_ids[1:10], .before = 1)

preview_df %>%
  gt() %>%
  tab_header(title = "PCA Input (First 10 Companies, First 6 Standardized Features)") %>%
  tab_options(table.font.size = "small", data_row.padding = px(3)) %>%
  gtsave("img_pca_sample.png", expand = 10)

# --- 2. Concept image: high-dimensional data is hard to visualize ---
set.seed(1)
demo3d <- data.frame(
  x = rnorm(200),
  y = rnorm(200),
  z = rnorm(200)
)

p1 <- ggplot(demo3d, aes(x, y)) +
  geom_point(alpha = 0.4, color = "steelblue") +
  labs(title = "Original Data: Hard to See Structure",
       subtitle = "In high dimensions, patterns are hidden",
       x = NULL, y = NULL) +
  theme_minimal()
ggsave("img_pca_concept_1.png", p1, width = 6, height = 4, dpi = 150)

# --- 3. Concept image: PCA projects onto a lower-dimensional space ---
set.seed(2)
demo_ellipse <- data.frame(
  x = c(rnorm(100, 0, 2), rnorm(100, 3, 2)),
  y = c(rnorm(100, 0, 0.5), rnorm(100, 3, 0.5))
)
pca_demo <- prcomp(demo_ellipse, center = TRUE, scale. = FALSE)

p2 <- ggplot(demo_ellipse, aes(x, y)) +
  geom_point(alpha = 0.4, color = "steelblue") +
  geom_segment(aes(x = 0, y = 0,
                   xend = pca_demo$rotation[1,1] * 4,
                   yend = pca_demo$rotation[2,1] * 4),
               arrow = arrow(length = unit(0.3, "cm")),
               color = "firebrick", linewidth = 1) +
  geom_segment(aes(x = 0, y = 0,
                   xend = pca_demo$rotation[1,2] * 1.5,
                   yend = pca_demo$rotation[2,2] * 1.5),
               arrow = arrow(length = unit(0.3, "cm")),
               color = "darkorange", linewidth = 0.8) +
  labs(title = "PCA Finds the Directions of Maximum Variance",
       subtitle = "Red arrow = PC1 (most variance), orange = PC2",
       x = NULL, y = NULL) +
  theme_minimal()
ggsave("img_pca_concept_2.png", p2, width = 6, height = 4, dpi = 150)