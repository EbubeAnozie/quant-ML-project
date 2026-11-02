library(readr)
library(dplyr)
library(gt)
library(ggplot2)

# 1. Load and merge
fin    <- read_csv("data/clean/company_financials_clean.csv", show_col_types = FALSE)
market <- read_csv("data/clean/market_data_clean.csv", show_col_types = FALSE)
merged <- inner_join(fin, market, by = c("ticker", "company", "sector")) %>% na.omit()

# 2. Create Binary Target (High_ROA: Yes if ROA > median)
med_roa <- median(merged$ROA)
merged <- merged %>%
  mutate(High_ROA = ifelse(ROA > med_roa, "Yes", "No")) %>%
  select(ticker, High_ROA, Revenue, TotalAssets, Debt_to_Equity, volatility, beta)

# 3. Convert numeric to categorical bins (Low, Medium, High)
bin_var <- function(x, var_name) {
  cuts <- quantile(x, probs = c(0, 0.33, 0.66, 1), na.rm = TRUE)
  cut(x, breaks = cuts, labels = c("Low", "Medium", "High"), include.lowest = TRUE)
}

nb_df <- merged %>%
  mutate(
    Revenue_Bin = bin_var(Revenue, "Revenue"),
    Assets_Bin  = bin_var(TotalAssets, "Assets"),
    Debt_Bin    = bin_var(Debt_to_Equity, "Debt"),
    Vol_Bin     = bin_var(volatility, "Vol"),
    Beta_Bin    = bin_var(beta, "Beta")
  ) %>%
  select(ticker, High_ROA, Revenue_Bin, Assets_Bin, Debt_Bin, Vol_Bin, Beta_Bin)

# Save the full labeled dataset
write_csv(nb_df, "data/clean/naive_bayes_data.csv")

# 4. Train/Test Split (70/30)
set.seed(42)
train_idx <- sample(1:nrow(nb_df), size = 0.7 * nrow(nb_df))
train_df  <- nb_df[train_idx, ]
test_df   <- nb_df[-train_idx, ]

write_csv(train_df, "data/clean/nb_train.csv")
write_csv(test_df, "data/clean/nb_test.csv")

# 5. Generate Images for Website
# Image 1: Sample of Labeled Data
nb_df %>% head(10) %>%
  gt() %>%
  tab_header(title = "Labeled Dataset for Naïve Bayes") %>%
  tab_options(table.font.size = "small", data_row.padding = px(3)) %>%
  gtsave("img_nb_data.png", expand = 10)

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
  gtsave("img_nb_split.png", expand = 10)

# Image 3: Train/Test Distribution
p_target <- ggplot(nb_df, aes(x = High_ROA, fill = High_ROA)) +
  geom_bar() +
  labs(title = "Distribution of Target Variable (High_ROA)",
       x = "High ROA", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("img_nb_target.png", p_target, width = 6, height = 4, dpi = 150)

library(ggplot2)

library(ggplot2)

# =========================================================
# Image 1: Multinomial NB (Counts/Frequencies)
# =========================================================
# Imagine classifying text: we count how often words appear
text_data <- data.frame(
  Word = rep(c("Free", "Win", "Meeting", "Project"), 2),
  Count = c(15, 12, 2, 1, 3, 1, 18, 14),
  Class = rep(c("Spam", "Not Spam"), each = 4)
)

p1 <- ggplot(text_data, aes(x = Word, y = Count, fill = Class)) +
  geom_col(position = "dodge", color = "white") +
  labs(title = "Multinomial NB: Counts / Frequencies",
       subtitle = "Models how often features occur (e.g., word counts)",
       x = "Feature (Word)", y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

ggsave("img_nb_concept_1.png", p1, width = 6, height = 4, dpi = 150)

# =========================================================
# Image 2: Bernoulli NB (Binary Presence/Absence)
# =========================================================
# Imagine classifying text: we only care if a word is there or not (1 or 0)
binary_data <- expand.grid(
  Feature = c("Free", "Win", "Meeting", "Project"),
  Document = c("Doc 1", "Doc 2", "Doc 3", "Doc 4")
)
binary_data$Present <- c(
  1, 0, 0, 0, # Doc 1
  1, 1, 0, 0, # Doc 2
  0, 0, 1, 1, # Doc 3
  0, 0, 1, 0  # Doc 4
)

p2 <- ggplot(binary_data, aes(x = Document, y = Feature, fill = factor(Present))) +
  geom_tile(color = "white", linewidth = 1) +
  scale_fill_manual(values = c("0" = "#f0f0f0", "1" = "#4682B4"),
                    labels = c("Absent (0)", "Present (1)")) +
  labs(title = "Bernoulli NB: Binary Presence / Absence",
       subtitle = "Models if a feature occurs at all (e.g., is the word present?)",
       x = "Document", y = "Feature (Word)", fill = "State") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

ggsave("img_nb_concept_2.png", p2, width = 6, height = 4, dpi = 150)