###############################################################################
# Phase 7: Exploratory Analyses
###############################################################################

library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")
load("analysis/output/processed_data.RData")
outdir <- "analysis/output/figures"

###########################################################################
# 7.1 Emotion Ratings x Headtracking
###########################################################################

cat("===== PHASE 7: EXPLORATORY ANALYSES =====\n")
cat("\n--- 7.1 Emotion Ratings x Headtracking ---\n")

# Correlations between valence/arousal and headtracking (per video, using long format)
ht_long_emo <- ht_merged

# Add valence and arousal from survey
for (v in 1:5) {
  mask <- ht_long_emo$video == paste0("v", v)
  for (p_idx in unique(ht_long_emo$participant_idx[mask])) {
    row_mask <- ht_long_emo$participant_idx == p_idx & ht_long_emo$video == paste0("v", v)
    survey_row <- which(full_data$participant_idx == p_idx)
    if (length(survey_row) == 1) {
      ht_long_emo$valence[row_mask] <- full_data[[paste0("valence_v", v)]][survey_row]
      ht_long_emo$arousal[row_mask] <- full_data[[paste0("arousal_v", v)]][survey_row]
      ht_long_emo$immersion[row_mask] <- full_data[[paste0("immersion_v", v)]][survey_row]
    }
  }
}

cat("\nCorrelations between emotion ratings and headtracking (pooled across videos):\n")
cat(sprintf("%-20s  r(Valence)  p-val      r(Arousal)  p-val\n", "HT Metric"))
cat(paste(rep("-", 70), collapse = ""), "\n")

for (metric in c("mean_speed", "sd_yaw", "sd_pitch", "sd_roll", "total_movement")) {
  cr_v <- cor.test(ht_long_emo[[metric]], ht_long_emo$valence, 
                   use = "complete.obs", method = "spearman", exact = FALSE)
  cr_a <- cor.test(ht_long_emo[[metric]], ht_long_emo$arousal, 
                   use = "complete.obs", method = "spearman", exact = FALSE)
  cat(sprintf("%-20s  %+.3f       %.4f     %+.3f       %.4f%s\n",
              metric, cr_v$estimate, cr_v$p.value, cr_a$estimate, cr_a$p.value,
              ifelse(cr_v$p.value < 0.05 | cr_a$p.value < 0.05, " *", "")))
}

# Scatter: valence vs mean_speed
p_val_speed <- ggplot(ht_long_emo, aes(x = valence, y = mean_speed)) +
  geom_jitter(aes(color = video), width = 0.2, alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", alpha = 0.2) +
  labs(title = "Valence vs Mean Rotation Speed", x = "Valence", y = "Mean Speed (°/s)") +
  theme_minimal()

p_aro_speed <- ggplot(ht_long_emo, aes(x = arousal, y = mean_speed)) +
  geom_jitter(aes(color = video), width = 0.2, alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", alpha = 0.2) +
  labs(title = "Arousal vs Mean Rotation Speed", x = "Arousal", y = "Mean Speed (°/s)") +
  theme_minimal()

g_emo <- arrangeGrob(p_val_speed, p_aro_speed, ncol = 2)
ggsave(file.path(outdir, "fig14_emotion_vs_speed.png"), g_emo, width = 12, height = 5, dpi = 150)
cat("Saved: fig14_emotion_vs_speed.png\n")

###########################################################################
# 7.2 PANAS x Headtracking
###########################################################################

cat("\n--- 7.2 PANAS (Pre-experiment Mood) x Headtracking ---\n")

panas_vars <- c("positive_affect_start", "negative_affect_start")
panas_labels <- c("PANAS Positive", "PANAS Negative")

cat(sprintf("%-20s  %-18s  r        p-value\n", "HT Metric", "PANAS"))
cat(paste(rep("-", 65), collapse = ""), "\n")

for (ht in c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch")) {
  for (i in seq_along(panas_vars)) {
    cr <- cor.test(full_data[[ht]], full_data[[panas_vars[i]]], 
                   use = "complete.obs", method = "pearson")
    sig <- ifelse(cr$p.value < 0.05, " *", "")
    cat(sprintf("%-20s  %-18s  %+.3f    %.4f%s\n",
                ht, panas_labels[i], cr$estimate, cr$p.value, sig))
  }
}

###########################################################################
# 7.3 Presence (Immersion) x Headtracking
###########################################################################

cat("\n--- 7.3 Presence/Immersion x Headtracking ---\n")

cat(sprintf("%-20s  r(Immersion)  p-value\n", "HT Metric"))
cat(paste(rep("-", 50), collapse = ""), "\n")

for (metric in c("mean_speed", "sd_yaw", "sd_pitch")) {
  cr <- cor.test(ht_long_emo[[metric]], ht_long_emo$immersion,
                 use = "complete.obs", method = "spearman", exact = FALSE)
  cat(sprintf("%-20s  %+.3f         %.4f%s\n",
              metric, cr$estimate, cr$p.value,
              ifelse(cr$p.value < 0.05, " *", "")))
}

# Immersion vs speed scatter
p_imm <- ggplot(ht_long_emo, aes(x = immersion, y = mean_speed)) +
  geom_jitter(aes(color = video), width = 0.3, alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", alpha = 0.2) +
  labs(title = "Immersion/Presence vs Mean Rotation Speed",
       x = "Immersion Score", y = "Mean Speed (°/s)") +
  theme_minimal()

ggsave(file.path(outdir, "fig15_immersion_vs_speed.png"), p_imm, width = 7, height = 5, dpi = 150)
cat("Saved: fig15_immersion_vs_speed.png\n")

###########################################################################
# 7.4 PANAS Pre vs Post (Paired t-test)
###########################################################################

cat("\n--- 7.4 PANAS Pre vs Post VR Experience ---\n")

# Positive Affect
pa_pre <- full_data$positive_affect_start
pa_post <- full_data$positive_affect_end
cat("Positive Affect:\n")
cat(sprintf("  Pre:  M = %.2f, SD = %.2f\n", mean(pa_pre), sd(pa_pre)))
cat(sprintf("  Post: M = %.2f, SD = %.2f\n", mean(pa_post), sd(pa_post)))
cat(sprintf("  Diff: M = %.2f\n", mean(pa_post - pa_pre)))

# Normality of differences
sw_pa <- shapiro.test(pa_post - pa_pre)
cat(sprintf("  Shapiro-Wilk on differences: W = %.4f, p = %.4f\n", sw_pa$statistic, sw_pa$p.value))

if (sw_pa$p.value > 0.05) {
  tt_pa <- t.test(pa_pre, pa_post, paired = TRUE)
  cat(sprintf("  Paired t-test: t(%d) = %.3f, p = %.4f\n", tt_pa$parameter, tt_pa$statistic, tt_pa$p.value))
} else {
  wt_pa <- wilcox.test(pa_pre, pa_post, paired = TRUE, exact = FALSE)
  cat(sprintf("  Wilcoxon signed-rank: V = %.0f, p = %.4f\n", wt_pa$statistic, wt_pa$p.value))
}

# Cohen's d for paired
d_pa <- mean(pa_post - pa_pre) / sd(pa_post - pa_pre)
cat(sprintf("  Cohen's d = %.3f\n", d_pa))

# Negative Affect
na_pre <- full_data$negative_affect_start
na_post <- full_data$negative_affect_end
cat("\nNegative Affect:\n")
cat(sprintf("  Pre:  M = %.2f, SD = %.2f\n", mean(na_pre), sd(na_pre)))
cat(sprintf("  Post: M = %.2f, SD = %.2f\n", mean(na_post), sd(na_post)))
cat(sprintf("  Diff: M = %.2f\n", mean(na_post - na_pre)))

sw_na <- shapiro.test(na_post - na_pre)
cat(sprintf("  Shapiro-Wilk on differences: W = %.4f, p = %.4f\n", sw_na$statistic, sw_na$p.value))

if (sw_na$p.value > 0.05) {
  tt_na <- t.test(na_pre, na_post, paired = TRUE)
  cat(sprintf("  Paired t-test: t(%d) = %.3f, p = %.4f\n", tt_na$parameter, tt_na$statistic, tt_na$p.value))
} else {
  wt_na <- wilcox.test(na_pre, na_post, paired = TRUE, exact = FALSE)
  cat(sprintf("  Wilcoxon signed-rank: V = %.0f, p = %.4f\n", wt_na$statistic, wt_na$p.value))
}

d_na <- mean(na_post - na_pre) / sd(na_post - na_pre)
cat(sprintf("  Cohen's d = %.3f\n", d_na))

# PANAS change by depression group
cat("\nPANAS Change by Depression Group:\n")
for (g in c("Non-Depressed", "Depressed")) {
  sub <- full_data[full_data$dep_group_primary == g, ]
  cat(sprintf("  %s (n=%d):\n", g, nrow(sub)))
  cat(sprintf("    PA change: %.2f (%.2f)\n", 
              mean(sub$positive_affect_end - sub$positive_affect_start),
              sd(sub$positive_affect_end - sub$positive_affect_start)))
  cat(sprintf("    NA change: %.2f (%.2f)\n",
              mean(sub$negative_affect_end - sub$negative_affect_start),
              sd(sub$negative_affect_end - sub$negative_affect_start)))
}

# Visualization
panas_change <- data.frame(
  participant = rep(1:40, 4),
  measure = rep(c("Positive", "Positive", "Negative", "Negative"), each = 40),
  time = rep(c("Pre", "Post", "Pre", "Post"), each = 40),
  value = c(pa_pre, pa_post, na_pre, na_post)
)
panas_change$time <- factor(panas_change$time, levels = c("Pre", "Post"))

p_panas <- ggplot(panas_change, aes(x = time, y = value, fill = time)) +
  geom_boxplot(alpha = 0.7) +
  geom_line(aes(group = participant), alpha = 0.15) +
  facet_wrap(~measure, scales = "free_y") +
  scale_fill_manual(values = c("Pre" = "lightblue", "Post" = "lightyellow")) +
  labs(title = "PANAS: Pre vs Post VR Experience", x = "", y = "Score") +
  theme_minimal() + theme(legend.position = "none")

ggsave(file.path(outdir, "fig16_panas_pre_post.png"), p_panas, width = 9, height = 5, dpi = 150)
cat("Saved: fig16_panas_pre_post.png\n")

###########################################################################
# 7.5 Simulator Sickness (VRISE) Effects
###########################################################################

cat("\n--- 7.5 Simulator Sickness (VRISE) ---\n")

# VRISE vs Depression
cr_vd <- cor.test(full_data$score_vrise, full_data$score_phq, method = "spearman", exact = FALSE)
cat(sprintf("VRISE ~ PHQ-9: rho = %.3f, p = %.4f\n", cr_vd$estimate, cr_vd$p.value))

# VRISE vs headtracking
cat("\nVRISE vs Headtracking:\n")
for (ht in c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch")) {
  cr <- cor.test(full_data$score_vrise, full_data[[ht]], method = "spearman", exact = FALSE)
  cat(sprintf("  VRISE ~ %-15s: rho = %+.3f, p = %.4f\n", ht, cr$estimate, cr$p.value))
}

# VRISE group comparison
vrise_nd <- full_data$score_vrise[full_data$dep_group_primary == "Non-Depressed"]
vrise_d <- full_data$score_vrise[full_data$dep_group_primary == "Depressed"]
wt_vrise <- wilcox.test(vrise_nd, vrise_d, exact = FALSE)
cat(sprintf("\nVRISE by group: ND M=%.2f, D M=%.2f, Mann-Whitney p=%.4f\n",
            mean(vrise_nd), mean(vrise_d), wt_vrise$p.value))

###########################################################################
# Secondary Cutoff Sensitivity Analysis (PHQ >= 10)
###########################################################################

cat("\n\n--- SENSITIVITY ANALYSIS: PHQ-9 >= 10 Cutoff ---\n")
cat(sprintf("Below Moderate: n=%d, Moderate+: n=%d\n",
            sum(full_data$dep_group_secondary == "Below Moderate"),
            sum(full_data$dep_group_secondary == "Moderate+")))

for (v in paste0("v", 1:5)) {
  col <- paste0("mean_speed_", v)
  if (!col %in% names(full_data)) next
  
  x1 <- full_data[[col]][full_data$dep_group_secondary == "Below Moderate"]
  x2 <- full_data[[col]][full_data$dep_group_secondary == "Moderate+"]
  x1 <- x1[!is.na(x1)]; x2 <- x2[!is.na(x2)]
  
  tt <- t.test(x1, x2, var.equal = FALSE)
  pooled_sd <- sqrt(((length(x1)-1)*var(x1) + (length(x2)-1)*var(x2)) / (length(x1)+length(x2)-2))
  d <- (mean(x1) - mean(x2)) / pooled_sd
  
  cat(sprintf("  %s Mean Speed: BM=%.2f(%.2f) vs M+=%.2f(%.2f), t=%.2f, p=%.4f, d=%.3f\n",
              toupper(v), mean(x1), sd(x1), mean(x2), sd(x2),
              tt$statistic, tt$p.value, d))
}

# Save final data
save(full_data, ht_merged, ht_all, survey, results_df, ht_long_emo,
     file = "analysis/output/processed_data.RData")
cat("\nPhase 7 complete. All analyses done.\n")
