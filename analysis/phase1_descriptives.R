###############################################################################
# Phase 1: Descriptive Statistics & Visualization
###############################################################################

library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)
library(corrplot)

setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")
load("analysis/output/processed_data.RData")

outdir <- "analysis/output/figures"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ---- 1.1 Demographics Summary ----
cat("===== 1.1 DEMOGRAPHICS =====\n")
cat(sprintf("N = %d participants\n", nrow(full_data)))
cat(sprintf("Age: M = %.2f, SD = %.2f, Range = %d-%d\n",
            mean(full_data$age), sd(full_data$age), min(full_data$age), max(full_data$age)))
cat(sprintf("Gender: Male = %d (%.1f%%), Female = %d (%.1f%%)\n",
            sum(full_data$gender == 1), 100 * mean(full_data$gender == 1),
            sum(full_data$gender == 2), 100 * mean(full_data$gender == 2)))
cat(sprintf("VR Experience: Yes = %d (%.1f%%), No = %d (%.1f%%)\n",
            sum(full_data$vr_experience == 1), 100 * mean(full_data$vr_experience == 1),
            sum(full_data$vr_experience == 2), 100 * mean(full_data$vr_experience == 2)))

# ---- 1.2 Psychological Scales ----
cat("\n===== 1.2 PSYCHOLOGICAL SCALES =====\n")
psych_vars <- c("score_phq", "score_gad", "score_stai_t", "score_vrise",
                "positive_affect_start", "negative_affect_start",
                "positive_affect_end", "negative_affect_end")
psych_labels <- c("PHQ-9", "GAD-7", "STAI-T", "VRISE",
                  "PANAS Positive (Pre)", "PANAS Negative (Pre)",
                  "PANAS Positive (Post)", "PANAS Negative (Post)")

for (i in seq_along(psych_vars)) {
  x <- full_data[[psych_vars[i]]]
  cat(sprintf("%-25s: M = %6.2f, SD = %5.2f, Median = %5.1f, IQR = [%.1f, %.1f], Range = [%.0f, %.0f]\n",
              psych_labels[i], mean(x, na.rm=T), sd(x, na.rm=T), median(x, na.rm=T),
              quantile(x, 0.25, na.rm=T), quantile(x, 0.75, na.rm=T),
              min(x, na.rm=T), max(x, na.rm=T)))
}

# Histograms of psychological scales
p_phq <- ggplot(full_data, aes(x = score_phq)) +
  geom_histogram(binwidth = 2, fill = "steelblue", color = "white", alpha = 0.8) +
  labs(title = "PHQ-9 (Depression)", x = "Score", y = "Count") +
  theme_minimal()

p_gad <- ggplot(full_data, aes(x = score_gad)) +
  geom_histogram(binwidth = 2, fill = "coral", color = "white", alpha = 0.8) +
  labs(title = "GAD-7 (Anxiety)", x = "Score", y = "Count") +
  theme_minimal()

p_stai <- ggplot(full_data, aes(x = score_stai_t)) +
  geom_histogram(binwidth = 5, fill = "darkseagreen", color = "white", alpha = 0.8) +
  labs(title = "STAI-T (Trait Anxiety)", x = "Score", y = "Count") +
  theme_minimal()

p_vrise <- ggplot(full_data, aes(x = score_vrise)) +
  geom_histogram(binwidth = 2, fill = "mediumpurple", color = "white", alpha = 0.8) +
  labs(title = "VRISE (Simulator Sickness)", x = "Score", y = "Count") +
  theme_minimal()

g <- arrangeGrob(p_phq, p_gad, p_stai, p_vrise, ncol = 2)
ggsave(file.path(outdir, "fig1_psych_scales_histograms.png"), g, width = 10, height = 8, dpi = 150)
cat("\nSaved: fig1_psych_scales_histograms.png\n")

# ---- 1.3 Valence & Arousal by Video ----
cat("\n===== 1.3 VALENCE & AROUSAL BY VIDEO =====\n")
valence_cols <- paste0("valence_v", 1:5)
arousal_cols <- paste0("arousal_v", 1:5)
video_labels <- c("V1: Abandoned", "V2: Beach", "V3: Campus", "V4: Horror", "V5: Surf")

for (i in 1:5) {
  cat(sprintf("%-15s Valence: M=%.2f, SD=%.2f | Arousal: M=%.2f, SD=%.2f\n",
              video_labels[i],
              mean(full_data[[valence_cols[i]]], na.rm=T), sd(full_data[[valence_cols[i]]], na.rm=T),
              mean(full_data[[arousal_cols[i]]], na.rm=T), sd(full_data[[arousal_cols[i]]], na.rm=T)))
}

# Reshape for valence/arousal plots
va_long <- full_data %>%
  select(participant_idx, starts_with("valence_v"), starts_with("arousal_v")) %>%
  pivot_longer(
    cols = -participant_idx,
    names_to = c("measure", "video"),
    names_pattern = "(valence|arousal)_(v\\d)",
    values_to = "score"
  ) %>%
  mutate(video_label = factor(video, levels = paste0("v", 1:5), labels = video_labels))

p_val <- ggplot(va_long[va_long$measure == "valence", ], aes(x = video_label, y = score)) +
  geom_boxplot(fill = "lightblue", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "Valence Ratings by Video", x = "", y = "Valence (1=Unpleasant, 9=Pleasant)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

p_aro <- ggplot(va_long[va_long$measure == "arousal", ], aes(x = video_label, y = score)) +
  geom_boxplot(fill = "lightyellow", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "Arousal Ratings by Video", x = "", y = "Arousal (1=Calming, 9=Exciting)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

g2 <- arrangeGrob(p_val, p_aro, ncol = 2)
ggsave(file.path(outdir, "fig2_valence_arousal_boxplots.png"), g2, width = 12, height = 5, dpi = 150)
cat("Saved: fig2_valence_arousal_boxplots.png\n")

# Circumplex Model plot (mean valence vs mean arousal per video)
circumplex_df <- data.frame(
  video = video_labels,
  valence = sapply(valence_cols, function(c) mean(full_data[[c]], na.rm=T)),
  arousal = sapply(arousal_cols, function(c) mean(full_data[[c]], na.rm=T))
)

p_circ <- ggplot(circumplex_df, aes(x = valence, y = arousal, label = video)) +
  geom_point(size = 4, color = "darkred") +
  geom_text(hjust = -0.15, vjust = -0.5, size = 3.5) +
  geom_hline(yintercept = 5, linetype = "dashed", alpha = 0.4) +
  geom_vline(xintercept = 5, linetype = "dashed", alpha = 0.4) +
  xlim(1, 9) + ylim(1, 9) +
  labs(title = "Circumplex Model: Videos in Valence-Arousal Space",
       x = "Valence (Unpleasant → Pleasant)",
       y = "Arousal (Calming → Exciting)") +
  annotate("text", x = 1.5, y = 8.5, label = "Tense/Stressed", alpha = 0.4, size = 3) +
  annotate("text", x = 8.5, y = 8.5, label = "Excited/Happy", alpha = 0.4, size = 3) +
  annotate("text", x = 1.5, y = 1.5, label = "Sad/Depressed", alpha = 0.4, size = 3) +
  annotate("text", x = 8.5, y = 1.5, label = "Calm/Relaxed", alpha = 0.4, size = 3) +
  theme_minimal()

ggsave(file.path(outdir, "fig3_circumplex_model.png"), p_circ, width = 7, height = 6, dpi = 150)
cat("Saved: fig3_circumplex_model.png\n")

# ---- 1.4 Headtracking Descriptives ----
cat("\n===== 1.4 HEADTRACKING DESCRIPTIVES =====\n")

# Mean speed per video
speed_long <- ht_merged %>%
  mutate(video_label = factor(video, levels = paste0("v", 1:5), labels = video_labels)) %>%
  select(participant_idx, video_label, mean_speed, sd_pitch, sd_yaw, sd_roll, total_movement)

cat("\nMean Rotation Speed by Video:\n")
speed_long %>% group_by(video_label) %>%
  summarise(M = mean(mean_speed), SD = sd(mean_speed), 
            Median = median(mean_speed), .groups = "drop") %>%
  print()

cat("\nSD Yaw by Video:\n")
speed_long %>% group_by(video_label) %>%
  summarise(M = mean(sd_yaw), SD = sd(sd_yaw), .groups = "drop") %>%
  print()

# Box plots
p_speed <- ggplot(speed_long, aes(x = video_label, y = mean_speed)) +
  geom_boxplot(fill = "skyblue", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "Mean Rotation Speed by Video", x = "", y = "Mean Speed (°/s)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

p_sdyaw <- ggplot(speed_long, aes(x = video_label, y = sd_yaw)) +
  geom_boxplot(fill = "lightsalmon", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "SD of Yaw by Video", x = "", y = "SD Yaw (°)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

p_sdpitch <- ggplot(speed_long, aes(x = video_label, y = sd_pitch)) +
  geom_boxplot(fill = "lightgreen", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "SD of Pitch by Video", x = "", y = "SD Pitch (°)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

p_sdroll <- ggplot(speed_long, aes(x = video_label, y = sd_roll)) +
  geom_boxplot(fill = "plum", alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4, size = 1.5) +
  labs(title = "SD of Roll by Video", x = "", y = "SD Roll (°)") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 15, hjust = 1))

g3 <- arrangeGrob(p_speed, p_sdyaw, p_sdpitch, p_sdroll, ncol = 2)
ggsave(file.path(outdir, "fig4_headtracking_boxplots.png"), g3, width = 12, height = 10, dpi = 150)
cat("Saved: fig4_headtracking_boxplots.png\n")

# ---- 1.5 Correlation Matrix ----
cat("\n===== 1.5 CORRELATION MATRIX =====\n")

# Average headtracking across all videos
full_data$avg_mean_speed <- rowMeans(full_data[, paste0("mean_speed_v", 1:5)], na.rm = TRUE)
full_data$avg_sd_yaw     <- rowMeans(full_data[, paste0("sd_yaw_v", 1:5)], na.rm = TRUE)
full_data$avg_sd_pitch   <- rowMeans(full_data[, paste0("sd_pitch_v", 1:5)], na.rm = TRUE)
full_data$avg_sd_roll    <- rowMeans(full_data[, paste0("sd_roll_v", 1:5)], na.rm = TRUE)
full_data$avg_total_mvmt <- rowMeans(full_data[, paste0("total_movement_v", 1:5)], na.rm = TRUE)

corr_vars <- c("score_phq", "score_gad", "score_stai_t", "score_vrise",
               "positive_affect_start", "negative_affect_start",
               "avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch", "avg_sd_roll")
corr_labels <- c("PHQ-9", "GAD-7", "STAI-T", "VRISE",
                 "PANAS+", "PANAS-",
                 "Avg Speed", "Avg SD Yaw", "Avg SD Pitch", "Avg SD Roll")

cor_matrix <- cor(full_data[, corr_vars], use = "pairwise.complete.obs")
rownames(cor_matrix) <- corr_labels
colnames(cor_matrix) <- corr_labels

cat("Correlation matrix:\n")
print(round(cor_matrix, 3))

png(file.path(outdir, "fig5_correlation_matrix.png"), width = 800, height = 700, res = 120)
corrplot(cor_matrix, method = "color", type = "upper", 
         addCoef.col = "black", number.cex = 0.7,
         tl.col = "black", tl.srt = 45, tl.cex = 0.8,
         title = "Correlation Matrix: Psychological & Headtracking Measures",
         mar = c(0, 0, 2, 0))
dev.off()
cat("Saved: fig5_correlation_matrix.png\n")

# ---- 1.6 Distribution Checks (Density + Q-Q plots) ----
cat("\n===== 1.6 DISTRIBUTION CHECKS =====\n")

# Density plots for main headtracking variables
ht_avg_long <- full_data %>%
  select(participant_idx, avg_mean_speed, avg_sd_yaw, avg_sd_pitch, avg_sd_roll) %>%
  pivot_longer(-participant_idx, names_to = "variable", values_to = "value") %>%
  mutate(variable = factor(variable, 
                           levels = c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch", "avg_sd_roll"),
                           labels = c("Mean Speed", "SD Yaw", "SD Pitch", "SD Roll")))

p_density <- ggplot(ht_avg_long, aes(x = value)) +
  geom_density(fill = "steelblue", alpha = 0.5) +
  facet_wrap(~variable, scales = "free") +
  labs(title = "Density Plots: Headtracking Variables (Averaged Across Videos)",
       x = "Value", y = "Density") +
  theme_minimal()

ggsave(file.path(outdir, "fig6_density_plots.png"), p_density, width = 10, height = 7, dpi = 150)
cat("Saved: fig6_density_plots.png\n")

# Q-Q plots
qq_plots <- list()
qq_vars <- c("avg_mean_speed", "avg_sd_yaw", "avg_sd_pitch", "avg_sd_roll")
qq_labs <- c("Mean Speed", "SD Yaw", "SD Pitch", "SD Roll")

for (i in seq_along(qq_vars)) {
  df_qq <- data.frame(value = full_data[[qq_vars[i]]])
  qq_plots[[i]] <- ggplot(df_qq, aes(sample = value)) +
    stat_qq() + stat_qq_line(color = "red") +
    labs(title = qq_labs[i]) +
    theme_minimal()
}

g_qq <- arrangeGrob(grobs = qq_plots, ncol = 2)
ggsave(file.path(outdir, "fig7_qq_plots.png"), g_qq, width = 10, height = 8, dpi = 150)
cat("Saved: fig7_qq_plots.png\n")

# Shapiro-Wilk normality tests
cat("\nShapiro-Wilk Normality Tests (averaged headtracking):\n")
for (i in seq_along(qq_vars)) {
  sw <- shapiro.test(full_data[[qq_vars[i]]])
  cat(sprintf("  %-15s: W = %.4f, p = %.4f %s\n",
              qq_labs[i], sw$statistic, sw$p.value,
              ifelse(sw$p.value < 0.05, "* (non-normal)", "(normal)")))
}

# Save updated data with computed averages
save(full_data, ht_merged, ht_all, survey, file = "analysis/output/processed_data.RData")
cat("\nPhase 1 complete.\n")
