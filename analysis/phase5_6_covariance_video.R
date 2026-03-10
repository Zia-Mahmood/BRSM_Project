###############################################################################
# Phase 5: Depression-Anxiety Covariance
# Phase 6: Video Type Effects on Psychomotor Response
###############################################################################

library(ggplot2)
library(dplyr)
library(tidyr)
library(ppcor)
library(gridExtra)

setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")
load("analysis/output/processed_data.RData")
outdir <- "analysis/output/figures"

###############################################################################
# PHASE 5: DEPRESSION-ANXIETY COVARIANCE
###############################################################################

cat("===== PHASE 5: DEPRESSION-ANXIETY COVARIANCE =====\n")

# ---- 5.1 Correlation between PHQ-9 and GAD-7 ----
cat("\n--- 5.1 PHQ-9 & GAD-7 Correlation ---\n")

cor_pg <- cor.test(full_data$score_phq, full_data$score_gad, method = "pearson")
cor_pg_s <- cor.test(full_data$score_phq, full_data$score_gad, method = "spearman", exact = FALSE)

cat(sprintf("Pearson:  r = %.3f, t(%d) = %.3f, p = %.4f\n",
            cor_pg$estimate, cor_pg$parameter, cor_pg$statistic, cor_pg$p.value))
cat(sprintf("Spearman: rho = %.3f, p = %.4f\n", cor_pg_s$estimate, cor_pg_s$p.value))

# Also with STAI-T
cor_ps <- cor.test(full_data$score_phq, full_data$score_stai_t, method = "pearson")
cor_gs <- cor.test(full_data$score_gad, full_data$score_stai_t, method = "pearson")
cat(sprintf("\nPHQ-9 ~ STAI-T: r = %.3f, p = %.4f\n", cor_ps$estimate, cor_ps$p.value))
cat(sprintf("GAD-7 ~ STAI-T: r = %.3f, p = %.4f\n", cor_gs$estimate, cor_gs$p.value))

# Scatter plot
p_dep_anx <- ggplot(full_data, aes(x = score_phq, y = score_gad)) +
  geom_point(aes(color = dep_group_primary), size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkblue", alpha = 0.2) +
  scale_color_manual(values = c("Non-Depressed" = "steelblue", "Depressed" = "tomato")) +
  labs(title = sprintf("PHQ-9 vs GAD-7 (r = %.3f, p < .001)", cor_pg$estimate),
       x = "PHQ-9 (Depression)", y = "GAD-7 (Anxiety)", color = "Group") +
  theme_minimal()

ggsave(file.path(outdir, "fig11_phq_gad_scatter.png"), p_dep_anx, width = 8, height = 6, dpi = 150)
cat("Saved: fig11_phq_gad_scatter.png\n")

# ---- 5.2 Partial Correlations ----
cat("\n--- 5.2 Partial Correlations (PHQ ~ HT, controlling for GAD-7) ---\n")

ht_avg_vars <- c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch", "avg_sd_roll", "avg_total_mvmt")
ht_avg_labels <- c("Mean Speed", "SD Yaw", "SD Pitch", "SD Roll", "Total Movement")

# Compute avg_total_mvmt if not present
if (!"avg_total_mvmt" %in% names(full_data)) {
  full_data$avg_total_mvmt <- rowMeans(full_data[, paste0("total_movement_v", 1:5)], na.rm = TRUE)
}

cat(sprintf("\n%-20s  r(zero-order)  p-value    r(partial|GAD)  p-value\n", "HT Variable"))
cat(paste(rep("-", 80), collapse = ""), "\n")

for (i in seq_along(ht_avg_vars)) {
  # Zero-order correlation
  cc <- cor.test(full_data$score_phq, full_data[[ht_avg_vars[i]]], 
                 use = "complete.obs", method = "pearson")
  
  # Partial correlation controlling for GAD-7
  df_pc <- full_data[, c("score_phq", ht_avg_vars[i], "score_gad")]
  df_pc <- df_pc[complete.cases(df_pc), ]
  
  pc <- pcor.test(df_pc$score_phq, df_pc[[ht_avg_vars[i]]], df_pc$score_gad, method = "pearson")
  
  cat(sprintf("%-20s  %+.3f          %.4f     %+.3f           %.4f\n",
              ht_avg_labels[i], cc$estimate, cc$p.value,
              pc$estimate, pc$p.value))
}

# Also partial controlling for STAI-T
cat("\n--- Partial Correlations (PHQ ~ HT, controlling for STAI-T) ---\n")
cat(sprintf("%-20s  r(partial|STAI)  p-value\n", "HT Variable"))
cat(paste(rep("-", 55), collapse = ""), "\n")

for (i in seq_along(ht_avg_vars)) {
  df_pc <- full_data[, c("score_phq", ht_avg_vars[i], "score_stai_t")]
  df_pc <- df_pc[complete.cases(df_pc), ]
  
  pc <- pcor.test(df_pc$score_phq, df_pc[[ht_avg_vars[i]]], df_pc$score_stai_t, method = "pearson")
  
  cat(sprintf("%-20s  %+.3f            %.4f\n",
              ht_avg_labels[i], pc$estimate, pc$p.value))
}

# ---- 5.3 Stratified Analysis ----
cat("\n--- 5.3 Stratified Analysis (by GAD-7 level) ---\n")

# Split by GAD-7 median
gad_median <- median(full_data$score_gad)
full_data$gad_group <- ifelse(full_data$score_gad <= gad_median, "Low Anxiety", "High Anxiety")

cat(sprintf("GAD-7 median = %d\n", gad_median))
cat(sprintf("Low Anxiety (GAD <= %d): n = %d\n", gad_median, sum(full_data$gad_group == "Low Anxiety")))
cat(sprintf("High Anxiety (GAD > %d): n = %d\n", gad_median, sum(full_data$gad_group == "High Anxiety")))

# Depression effect on mean speed within each anxiety stratum
for (anx_level in c("Low Anxiety", "High Anxiety")) {
  sub <- full_data[full_data$gad_group == anx_level, ]
  cat(sprintf("\n  Stratum: %s (n=%d)\n", anx_level, nrow(sub)))
  
  nd <- sub$avg_mean_speed[sub$dep_group_primary == "Non-Depressed"]
  d  <- sub$avg_mean_speed[sub$dep_group_primary == "Depressed"]
  nd <- nd[!is.na(nd)]; d <- d[!is.na(d)]
  
  if (length(nd) >= 3 & length(d) >= 3) {
    tt <- t.test(nd, d, var.equal = FALSE)
    pooled_sd <- sqrt(((length(nd)-1)*var(nd) + (length(d)-1)*var(d)) / (length(nd)+length(d)-2))
    d_val <- (mean(nd) - mean(d)) / pooled_sd
    cat(sprintf("    Avg Mean Speed: ND M=%.2f, D M=%.2f, t=%.2f, p=%.4f, d=%.3f\n",
                mean(nd), mean(d), tt$statistic, tt$p.value, d_val))
  } else {
    cat(sprintf("    Insufficient data: ND n=%d, D n=%d\n", length(nd), length(d)))
  }
}

###############################################################################
# PHASE 6: VIDEO TYPE EFFECTS ON PSYCHOMOTOR RESPONSE
###############################################################################

cat("\n\n===== PHASE 6: VIDEO TYPE EFFECTS =====\n")

# ---- 6.0 Reshape to Long Format ----
cat("\n--- 6.0 Reshaping Data to Long Format ---\n")

video_labels_short <- c("V1:Abandoned", "V2:Beach", "V3:Campus", "V4:Horror", "V5:Surf")

ht_long <- ht_merged %>%
  mutate(video_label = factor(video, levels = paste0("v", 1:5), labels = video_labels_short))

cat("Long format data:", nrow(ht_long), "rows\n")

# ---- 6.1 Repeated Measures: Friedman Test ----
cat("\n--- 6.1 Friedman Test (Repeated Measures Across Videos) ---\n")

# Need complete cases across all 5 videos
speed_wide <- full_data %>%
  dplyr::select(participant_idx, mean_speed_v1, mean_speed_v2, mean_speed_v3, mean_speed_v4, mean_speed_v5) %>%
  dplyr::filter(complete.cases(.))

cat(sprintf("Complete cases for Friedman test: n = %d\n", nrow(speed_wide)))

# Friedman tests for primary metrics
friedman_metrics <- c("mean_speed", "sd_yaw", "sd_pitch")
friedman_labels <- c("Mean Rotation Speed", "SD Yaw", "SD Pitch")

for (i in seq_along(friedman_metrics)) {
  m <- friedman_metrics[i]
  cols <- paste0(m, "_v", 1:5)
  
  df_fr <- full_data[, c("participant_idx", cols)]
  df_fr <- df_fr[complete.cases(df_fr), ]
  
  mat <- as.matrix(df_fr[, cols])
  fr <- friedman.test(mat)
  
  cat(sprintf("\n%s:\n", friedman_labels[i]))
  cat(sprintf("  Friedman chi-squared = %.2f, df = %d, p = %.6f %s\n",
              fr$statistic, fr$parameter, fr$p.value,
              ifelse(fr$p.value < 0.05, "***", "")))
  
  # Video means
  for (v in 1:5) {
    cat(sprintf("    %s: M = %.2f\n", video_labels_short[v], mean(df_fr[[cols[v]]], na.rm=T)))
  }
}

# ---- 6.2 Post-hoc Pairwise Wilcoxon (for significant Friedman results) ----
cat("\n--- 6.2 Post-hoc Pairwise Wilcoxon Signed-Rank Tests ---\n")

for (i in seq_along(friedman_metrics)) {
  m <- friedman_metrics[i]
  cols <- paste0(m, "_v", 1:5)
  
  df_fr <- full_data[, c("participant_idx", cols)]
  df_fr <- df_fr[complete.cases(df_fr), ]
  
  # Pairwise Wilcoxon
  mat <- df_fr[, cols]
  n_videos <- 5
  cat(sprintf("\n%s - Pairwise Wilcoxon (Bonferroni corrected):\n", friedman_labels[i]))
  
  pairs <- combn(1:5, 2)
  p_vals_raw <- numeric(ncol(pairs))
  
  for (j in 1:ncol(pairs)) {
    v1 <- pairs[1, j]; v2 <- pairs[2, j]
    wt <- wilcox.test(mat[[cols[v1]]], mat[[cols[v2]]], paired = TRUE, exact = FALSE)
    p_vals_raw[j] <- wt$p.value
  }
  
  p_vals_adj <- p.adjust(p_vals_raw, method = "bonferroni")
  
  for (j in 1:ncol(pairs)) {
    v1 <- pairs[1, j]; v2 <- pairs[2, j]
    sig <- ifelse(p_vals_adj[j] < 0.05, "*", " ")
    cat(sprintf("  %s vs %s: p_raw=%.4f, p_adj=%.4f %s\n",
                video_labels_short[v1], video_labels_short[v2],
                p_vals_raw[j], p_vals_adj[j], sig))
  }
}

# ---- 6.3 Video Category Analysis ----
cat("\n--- 6.3 Video Category Analysis ---\n")
cat("Categories: Positive (V2:Beach, V5:Surf), Neutral (V3:Campus), Negative (V1:Abandoned, V4:Horror)\n\n")

ht_long$video_category <- factor(
  ifelse(ht_long$video %in% c("v2", "v5"), "Positive",
         ifelse(ht_long$video == "v3", "Neutral", "Negative")),
  levels = c("Positive", "Neutral", "Negative")
)

# Kruskal-Wallis for category differences
cat("Kruskal-Wallis tests by video category:\n")
for (metric in c("mean_speed", "sd_yaw", "sd_pitch")) {
  kw <- kruskal.test(as.formula(paste(metric, "~ video_category")), data = ht_long)
  cat(sprintf("  %-15s: H = %.2f, df = %d, p = %.4f %s\n",
              metric, kw$statistic, kw$parameter, kw$p.value,
              ifelse(kw$p.value < 0.05, "*", "")))
}

# Box plot by category
p_cat <- ggplot(ht_long, aes(x = video_category, y = mean_speed, fill = video_category)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("Positive" = "lightgreen", "Neutral" = "lightyellow", "Negative" = "salmon")) +
  labs(title = "Mean Rotation Speed by Video Emotional Category",
       x = "Video Category", y = "Mean Rotation Speed (°/s)") +
  theme_minimal() + theme(legend.position = "none")

ggsave(file.path(outdir, "fig12_speed_by_category.png"), p_cat, width = 7, height = 5, dpi = 150)
cat("Saved: fig12_speed_by_category.png\n")

# ---- 6.4 Interaction: Depression Group x Video Type ----
cat("\n--- 6.4 Depression Group x Video Type Interaction ---\n")

interaction_summary <- ht_long %>%
  dplyr::group_by(video_label, dep_group_primary) %>%
  dplyr::summarise(M = mean(mean_speed, na.rm = TRUE), 
            SD = sd(mean_speed, na.rm = TRUE),
            n = dplyr::n(), .groups = "drop")

print(interaction_summary)

p_interact <- ggplot(interaction_summary, aes(x = video_label, y = M, 
                                               color = dep_group_primary, group = dep_group_primary)) +
  geom_point(size = 3) +
  geom_line(linewidth = 1) +
  geom_errorbar(aes(ymin = M - SD/sqrt(n), ymax = M + SD/sqrt(n)), width = 0.2) +
  scale_color_manual(values = c("Non-Depressed" = "steelblue", "Depressed" = "tomato")) +
  labs(title = "Mean Rotation Speed: Depression Group × Video",
       x = "", y = "Mean Speed (°/s) ± SE", color = "Group") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

ggsave(file.path(outdir, "fig13_interaction_plot.png"), p_interact, width = 9, height = 5, dpi = 150)
cat("Saved: fig13_interaction_plot.png\n")

# Save
save(full_data, ht_merged, ht_all, survey, results_df, ht_long,
     file = "analysis/output/processed_data.RData")
cat("\nPhase 5 & 6 complete.\n")
