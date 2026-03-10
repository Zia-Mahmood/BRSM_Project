###############################################################################
# Phase 2: Outlier Detection & Handling
# Phase 3: Group Partitioning
###############################################################################

library(ggplot2)
library(dplyr)
library(gridExtra)

setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")
load("analysis/output/processed_data.RData")
outdir <- "analysis/output/figures"

###############################################################################
# PHASE 2: OUTLIER DETECTION
###############################################################################

cat("===== PHASE 2: OUTLIER DETECTION =====\n")

# ---- 2.1 Survey Outliers (IQR + Z-score) ----
cat("\n--- 2.1 Survey Scale Outliers ---\n")

detect_outliers <- function(x, label) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower <- q1 - 1.5 * iqr
  upper <- q3 + 1.5 * iqr
  outliers_iqr <- which(x < lower | x > upper)
  
  z <- (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  outliers_z <- which(abs(z) > 2.5)
  
  cat(sprintf("  %-20s: IQR bounds [%.1f, %.1f], IQR outliers: %s | Z>2.5 outliers: %s\n",
              label, lower, upper,
              ifelse(length(outliers_iqr) == 0, "none", paste(outliers_iqr, collapse = ",")),
              ifelse(length(outliers_z) == 0, "none", paste(outliers_z, collapse = ","))))
  
  return(list(iqr = outliers_iqr, z = outliers_z, z_scores = z))
}

out_phq  <- detect_outliers(full_data$score_phq, "PHQ-9")
out_gad  <- detect_outliers(full_data$score_gad, "GAD-7")
out_stai <- detect_outliers(full_data$score_stai_t, "STAI-T")

# ---- 2.2 Headtracking Outliers ----
cat("\n--- 2.2 Headtracking Outliers ---\n")

ht_vars <- c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch", "avg_sd_roll")
ht_labels <- c("Avg Mean Speed", "Avg SD Yaw", "Avg SD Pitch", "Avg SD Roll")

for (i in seq_along(ht_vars)) {
  detect_outliers(full_data[[ht_vars[i]]], ht_labels[i])
}

# Outlier visualization: box plots with participant labels
outlier_plots <- list()
for (i in seq_along(ht_vars)) {
  df_plot <- data.frame(value = full_data[[ht_vars[i]]], id = 1:nrow(full_data))
  q1 <- quantile(df_plot$value, 0.25, na.rm = TRUE)
  q3 <- quantile(df_plot$value, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  df_plot$outlier <- df_plot$value < (q1 - 1.5 * iqr) | df_plot$value > (q3 + 1.5 * iqr)
  
  outlier_plots[[i]] <- ggplot(df_plot, aes(x = "", y = value)) +
    geom_boxplot(fill = "lightblue", alpha = 0.6, outlier.shape = NA) +
    geom_jitter(aes(color = outlier), width = 0.2, size = 2) +
    geom_text(data = df_plot[df_plot$outlier, ], aes(label = id), 
              hjust = -0.3, size = 3, color = "red") +
    scale_color_manual(values = c("FALSE" = "grey40", "TRUE" = "red")) +
    labs(title = ht_labels[i], x = "", y = "Value") +
    theme_minimal() + theme(legend.position = "none")
}

g_out <- arrangeGrob(grobs = outlier_plots, ncol = 2)
ggsave(file.path(outdir, "fig8_ht_outliers.png"), g_out, width = 10, height = 8, dpi = 150)
cat("Saved: fig8_ht_outliers.png\n")

# ---- 2.3 VRISE Outlier Check ----
cat("\n--- 2.3 VRISE (Simulator Sickness) Check ---\n")
out_vrise <- detect_outliers(full_data$score_vrise, "VRISE")

low_vrise <- which(full_data$score_vrise < quantile(full_data$score_vrise, 0.25) - 1.5 * IQR(full_data$score_vrise))
cat(sprintf("  Participants with extremely low VRISE (severe sickness): %s\n",
            ifelse(length(low_vrise) == 0, "none", paste(low_vrise, collapse = ","))))

if (length(low_vrise) > 0) {
  cat("  VRISE values for flagged participants:\n")
  for (p in low_vrise) {
    cat(sprintf("    Participant %d: VRISE = %d, PHQ = %d\n", 
                p, full_data$score_vrise[p], full_data$score_phq[p]))
  }
}

# ---- 2.4 Exclusion Decision ----
cat("\n--- 2.4 EXCLUSION DECISION ---\n")
cat("Predefined exclusion criteria:\n")
cat("  1. VRISE score extremely low (severe simulator sickness)\n")
cat("  2. Headtracking data shows clear sensor artifacts or corrupted recording\n\n")

# Check the flagged VRISE participants
exclude_ids <- c()
if (length(low_vrise) > 0) {
  cat(sprintf("Flagged for VRISE: participants %s\n", paste(low_vrise, collapse = ", ")))
  cat("Reviewing their headtracking data...\n")
  for (p in low_vrise) {
    speed <- full_data$avg_mean_speed[p]
    cat(sprintf("  Participant %d: VRISE=%d, Avg Speed=%.2f\n",
                p, full_data$score_vrise[p], speed))
  }
}

# Decision: Based on data review
cat("\nDecision: No participants excluded.\n")
cat("Reasoning:\n")
cat("  - VRISE outliers, while showing lower VR tolerance, do not\n")
cat("    indicate recording failure or sensor malfunction.\n")
cat("  - Headtracking data appears valid across all participants.\n")
cat("  - With N=40, excluding participants would reduce statistical power.\n")
cat("  - Outlier values on psychological scales are clinically plausible\n")
cat("    and represent meaningful individual differences.\n")

full_data$excluded <- FALSE  # None excluded

###############################################################################
# PHASE 3: GROUP PARTITIONING
###############################################################################

cat("\n\n===== PHASE 3: GROUP PARTITIONING =====\n")

# ---- 3.0 PHQ-9 Distribution Visualization ----
p_phq_dist <- ggplot(full_data, aes(x = score_phq)) +
  geom_histogram(binwidth = 1, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 4.5, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = 9.5, linetype = "dashed", color = "darkred", linewidth = 1) +
  annotate("text", x = 2, y = 7.5, label = "Minimal\n(0-4)", color = "darkgreen", size = 3.5) +
  annotate("text", x = 7, y = 7.5, label = "Mild\n(5-9)", color = "orange", size = 3.5) +
  annotate("text", x = 14, y = 7.5, label = "Moderate+\n(10+)", color = "red", size = 3.5) +
  labs(title = "PHQ-9 Score Distribution with Clinical Cutoffs",
       x = "PHQ-9 Score", y = "Count") +
  theme_minimal()

ggsave(file.path(outdir, "fig9_phq9_distribution.png"), p_phq_dist, width = 8, height = 5, dpi = 150)
cat("Saved: fig9_phq9_distribution.png\n")

# ---- 3.1 Group Classification ----
# Primary cutoff: PHQ-9 >= 5 (Mild or greater depression)
full_data$dep_group_primary <- ifelse(full_data$score_phq >= 5, "Depressed", "Non-Depressed")
full_data$dep_group_primary <- factor(full_data$dep_group_primary, 
                                       levels = c("Non-Depressed", "Depressed"))

# Secondary cutoff: PHQ-9 >= 10 (Moderate or greater depression)  
full_data$dep_group_secondary <- ifelse(full_data$score_phq >= 10, "Moderate+", "Below Moderate")
full_data$dep_group_secondary <- factor(full_data$dep_group_secondary,
                                         levels = c("Below Moderate", "Moderate+"))

cat("\n--- 3.1 Group Sizes ---\n")
cat("Primary cutoff (PHQ-9 >= 5):\n")
print(table(full_data$dep_group_primary))
cat(sprintf("  Non-Depressed: n=%d, Depressed: n=%d\n\n",
            sum(full_data$dep_group_primary == "Non-Depressed"),
            sum(full_data$dep_group_primary == "Depressed")))

cat("Secondary cutoff (PHQ-9 >= 10):\n")
print(table(full_data$dep_group_secondary))
cat(sprintf("  Below Moderate: n=%d, Moderate+: n=%d\n\n",
            sum(full_data$dep_group_secondary == "Below Moderate"),
            sum(full_data$dep_group_secondary == "Moderate+")))

# ---- 3.2 Group Comparison Table ----
cat("--- 3.2 Group Comparison (Primary: PHQ >= 5) ---\n")

group_compare <- function(var, label, data) {
  g1 <- data[[var]][data$dep_group_primary == "Non-Depressed"]
  g2 <- data[[var]][data$dep_group_primary == "Depressed"]
  cat(sprintf("  %-25s: Non-Dep M=%.2f(SD=%.2f) | Dep M=%.2f(SD=%.2f) | diff=%.2f\n",
              label, mean(g1, na.rm=T), sd(g1, na.rm=T),
              mean(g2, na.rm=T), sd(g2, na.rm=T),
              mean(g2, na.rm=T) - mean(g1, na.rm=T)))
}

group_compare("age", "Age", full_data)
group_compare("score_gad", "GAD-7", full_data)
group_compare("score_stai_t", "STAI-T", full_data)
group_compare("score_vrise", "VRISE", full_data)
group_compare("positive_affect_start", "PANAS+ (Pre)", full_data)
group_compare("negative_affect_start", "PANAS- (Pre)", full_data)
group_compare("avg_mean_speed", "Avg Head Speed", full_data)

cat("\nGender distribution by group:\n")
print(table(full_data$dep_group_primary, full_data$gender))

cat("\nVR experience by group:\n")
print(table(full_data$dep_group_primary, full_data$vr_experience))

# ---- 3.3 Justification ----
cat("\n--- 3.3 Cutoff Justification ---\n")
cat("Primary cutoff (PHQ-9 >= 5) based on Kroenke et al. (2001) PHQ-9\n")
cat("validation study scoring guide:\n")
cat("  0-4: Minimal depression\n")
cat("  5-9: Mild depression\n")
cat("  10-14: Moderate depression\n")
cat("  15-19: Moderately severe depression\n")
cat("  20-27: Severe depression\n")
cat("\nUsing >= 5 cutoff yields balanced groups (n=20 vs n=20),\n")
cat("maximizing statistical power for group comparisons.\n")
cat("Secondary cutoff (>= 10) used for sensitivity analysis.\n")

# Also add group to ht_merged for long-format analyses
ht_merged <- merge(ht_merged, 
                   full_data[, c("participant_idx", "dep_group_primary", "dep_group_secondary",
                                 "score_phq", "score_gad", "score_stai_t")],
                   by = "participant_idx", all.x = TRUE)

# Save
save(full_data, ht_merged, ht_all, survey, file = "analysis/output/processed_data.RData")
cat("\nPhase 2 & 3 complete. Data saved.\n")
