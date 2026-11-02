library(readr)
library(dplyr)
library(gt)
library(ggplot2)
library(rpart)
library(rpart.plot)

# 1. Load and merge
fin    <- read_csv("data/clean/company_financials_clean.csv", show_col_types = FALSE)
market <- read_csv("data/clean/market_data_clean.csv", show_col_types = FALSE)
merged <- inner_join(fin, market, by = c("ticker", "company", "sector")) %>% na.omit()

# 2. Create Binary Target (High_ROA)
med_roa <- median(merged$ROA)
dt_df <- merged %>%
  mutate(High_ROA = as.factor(ifelse(ROA > med_roa, "Yes", "No"))) %>%
  # Unlike Naive Bayes, we keep the raw continuous numbers!
  select(ticker, High_ROA, Revenue, TotalAssets, Debt_to_Equity, volatility, beta)

write_csv(dt_df, "data/clean/decision_tree_data.csv")

# 3. Train/Test Split (70/30)
set.seed(42)
train_idx <- sample(1:nrow(dt_df), size = 0.7 * nrow(dt_df))
train_df  <- dt_df[train_idx, ]
test_df   <- dt_df[-train_idx, ]

write_csv(train_df, "data/clean/dt_train.csv")
write_csv(test_df, "data/clean/dt_test.csv")

# 4. Generate Images
# Image 1: Sample of continuous labeled data
dt_df %>% head(10) %>%
  gt() %>%
  tab_header(title = "Labeled Dataset for Decision Trees") %>%
  fmt_number(columns = c(Revenue, TotalAssets), decimals = 0) %>%
  fmt_number(columns = c(Debt_to_Equity, volatility, beta), decimals = 3) %>%
  tab_options(table.font.size = "small", data_row.padding = px(3)) %>%
  gtsave("img_dt_data.png", expand = 10)

# Image 2: Train/Test Split
split_summary <- data.frame(
  Set = c("Training Set", "Testing Set"),
  Rows = c(nrow(train_df), nrow(test_df)),
  Percentage = c("70%", "30%")
)
split_summary %>%
  gt() %>%
  tab_header(title = "Train/Test Split Summary") %>%
  tab_options(table.font.size = "small", data_row.padding = px(3)) %>%
  gtsave("img_dt_split.png", expand = 10)

# 5. Generate Concept Images for Overview
# Concept 1: A simple flowchart style tree
png("img_dt_concept_1.png", width = 800, height = 500, res = 120)
par(mar = c(1,1,1,1))
plot(0, 0, type = "n", xlim = c(0, 10), ylim = c(0, 10), axes = FALSE, xlab = "", ylab = "")
text(5, 8, "Revenue > $50B?", cex = 1.2, font = 2)
rect(2.5, 7.2, 7.5, 8.8, border = "steelblue", lwd = 2)
arrows(4, 7.2, 2.5, 5.5, length = 0.1)
arrows(6, 7.2, 7.5, 5.5, length = 0.1)
text(3, 6, "Yes", cex = 1)
text(7, 6, "No", cex = 1)
text(2.5, 4.5, "Debt < 2?", cex = 1)
text(7.5, 4.5, "High ROA", cex = 1)
rect(0.5, 3.7, 4.5, 5.3, border = "steelblue", lwd = 2)
rect(6, 3.7, 9, 5.3, border = "darkgreen", lwd = 2, col = "#e0f7e0")
text(1.5, 2.5, "No", cex = 1)
text(3.5, 2.5, "Yes", cex = 1)
text(1.5, 1.5, "Low ROA", cex = 1)
text(3.5, 1.5, "High ROA", cex = 1)
dev.off()

# Concept 2: A visual of a multi-level tree using rpart.plot on dummy data
set.seed(123)
dummy_data <- data.frame(
  Target = factor(sample(c("Yes", "No"), 100, replace = TRUE)),
  Feature1 = rnorm(100),
  Feature2 = rnorm(100)
)
dummy_tree <- rpart(Target ~ ., data = dummy_data)
png("img_dt_concept_2.png", width = 800, height = 500, res = 120)
rpart.plot(dummy_tree, main = "Example Tree: Recursive Partitioning")
dev.off()