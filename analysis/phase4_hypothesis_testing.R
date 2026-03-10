###############################################################################
# Phase 4: Core Hypothesis Testing - Depression x Head-Tracking
###############################################################################

library(ggplot2)
library(dplyr)
library(tidyr)
library(car)
library(gridExtra)

setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")
load("analysis/output/processed_data.RData")
outdir <- "analysis/output/figures"

# ---- 4.0 Define Primary vs Secondary Metrics ----
cat("===== PHASE 4: CORE HYPOTHESIS TESTING =====\n")
cat("\nPrimary headtracking metrics: Mean Rotation Speed, SD Yaw, SD Pitch\n")
cat("Secondary headtracking metrics: SD Roll, Total Movement Magnitude\n")

primary_metrics  <- c("mean_speed", "sd_yaw", "sd_pitch")
secondary_metrics <- c("sd_roll", "total_movement")
all_metrics <- c(primary_metrics, secondary_metrics)
metric_labels <- c("Mean Rotation Speed", "SD Yaw", "SD Pitch", "SD Roll", "Total Movement")

videos <- paste0("v", 1:5)
video_labels <- c("V1: Abandoned", "V2: Beach", "V3: Campus", "V4: Horror", "V5: Surf")

# ---- 4.1 & 4.2 Normality and Variance Tests ----
cat("\n--- 4.1 & 4.2 Normality (Shapiro-Wilk) & Variance (Levene's) Tests ---\n")

results_list <- list()
test_counter <- 0

for (m in seq_along(all_metrics)) {
  metric <- all_metrics[m]
  cat(sprintf("\n== %s ==\n", metric_labels[m]))
  
  for (v in seq_along(videos)) {
    col_name <- paste0(metric, "_", videos[v])
    if (!col_name %in% names(full_data)) next
    
    x_nd <- full_data[[col_name]][full_data$dep_group_primary == "Non-Depressed"]
    x_d  <- full_data[[col_name]][full_data$dep_group_primary == "Depressed"]
    
    # Remove NAs
    x_nd <- x_nd[!is.na(x_nd)]
    x_d  <- x_d[!is.na(x_d)]
    
    # Shapiro-Wilk per group
    sw_nd <- shapiro.test(x_nd)
    sw_d  <- shapiro.test(x_d)
    normal_nd <- sw_nd$p.value > 0.05
    normal_d  <- sw_d$p.value > 0.05
    both_normal <- normal_nd & normal_d
    
    # Levene's test
    df_lev <- data.frame(
      value = full_data[[col_name]], 
      group = full_data$dep_group_primary
    )
    df_lev <- df_lev[!is.na(df_lev$value), ]
    lev <- leveneTest(value ~ group, data = df_lev)
    equal_var <- lev$`Pr(>F)`[1] > 0.05
    
    # ---- 4.3 Group Comparison ----
    if (both_normal) {
      # Welch's t-test (does not assume equal variances)
      tt <- t.test(x_nd, x_d, var.equal = FALSE)
      test_type <- "Welch t"
      stat_val <- tt$statistic
      p_val <- tt$p.value
      df_val <- tt$parameter
    } else {
      # Mann-Whitney U
      wt <- wilcox.test(x_nd, x_d, exact = FALSE)
      test_type <- "Mann-Whitney"
      stat_val <- wt$statistic
      p_val <- wt$p.value
      df_val <- NA
    }
    
    # ---- 4.4 Effect Size (Cohen's d) ----
    pooled_sd <- sqrt(((length(x_nd) - 1) * var(x_nd) + (length(x_d) - 1) * var(x_d)) / 
                        (length(x_nd) + length(x_d) - 2))
    cohens_d <- (mean(x_nd) - mean(x_d)) / pooled_sd
    d_interpret <- ifelse(abs(cohens_d) >= 0.8, "Large",
                          ifelse(abs(cohens_d) >= 0.5, "Medium",
                                 ifelse(abs(cohens_d) >= 0.2, "Small", "Negligible")))
    
    test_counter <- test_counter + 1
    
    cat(sprintf("  %s: ND M=%.2f(%.2f), D M=%.2f(%.2f) | %s: p=%.4f | d=%.3f (%s)\n",
                video_labels[v],
                mean(x_nd), sd(x_nd), mean(x_d), sd(x_d),
                test_type, p_val, cohens_d, d_interpret))
    cat(sprintf("    Normality: ND p=%.3f%s, D p=%.3f%s | Levene p=%.3f%s\n",
                sw_nd$p.value, ifelse(normal_nd, "", "*"),
                sw_d$p.value, ifelse(normal_d, "", "*"),
                lev$`Pr(>F)`[1], ifelse(equal_var, "", "*")))
    
    results_list[[test_counter]] <- data.frame(
      metric = metric_labels[m],
      metric_type = ifelse(metric %in% primary_metrics, "Primary", "Secondary"),
      video = video_labels[v],
      n_nd = length(x_nd), n_d = length(x_d),
      mean_nd = mean(x_nd), sd_nd = sd(x_nd),
      mean_d = mean(x_d), sd_d = sd(x_d),
      test = test_type,
      statistic = stat_val,
      p_value = p_val,
      cohens_d = cohens_d,
      d_interpret = d_interpret,
      stringsAsFactors = FALSE
    )
  }
}

results_df <- do.call(rbind, results_list)

# ---- 4.5 Multiple Comparisons Correction ----
cat("\n\n--- 4.5 Multiple Comparisons Correction ---\n")
cat(sprintf("Total tests conducted: %d\n", nrow(results_df)))

# Bonferroni correction
results_df$p_bonferroni <- p.adjust(results_df$p_value, method = "bonferroni")

# Benjamini-Hochberg (FDR)
results_df$p_bh <- p.adjust(results_df$p_value, method = "BH")

# Separate corrections for primary and secondary
results_df$p_bh_primary <- NA
primary_idx <- results_df$metric_type == "Primary"
results_df$p_bh_primary[primary_idx] <- p.adjust(results_df$p_value[primary_idx], method = "BH")

cat("\n===== FULL RESULTS TABLE =====\n")
cat(sprintf("%-22s %-15s %-12s  p-raw    p-BH     p-Bonf   Cohen's d  Interp\n",
            "Metric", "Video", "Test"))
cat(paste(rep("-", 110), collapse = ""), "\n")

for (i in 1:nrow(results_df)) {
  r <- results_df[i, ]
  sig_raw <- ifelse(r$p_value < 0.05, "*", " ")
  sig_bh  <- ifelse(r$p_bh < 0.05, "*", " ")
  sig_bon <- ifelse(r$p_bonferroni < 0.05, "*", " ")
  cat(sprintf("%-22s %-15s %-12s  %.4f%s  %.4f%s  %.4f%s  %+.3f     %s\n",
              r$metric, r$video, r$test,
              r$p_value, sig_raw, r$p_bh, sig_bh, r$p_bonferroni, sig_bon,
              r$cohens_d, r$d_interpret))
}

# Count significant results
cat(sprintf("\nSignificant at p < 0.05 (raw): %d / %d\n", sum(results_df$p_value < 0.05), nrow(results_df)))
cat(sprintf("Significant at p < 0.05 (BH-corrected): %d / %d\n", sum(results_df$p_bh < 0.05), nrow(results_df)))
cat(sprintf("Significant at p < 0.05 (Bonferroni): %d / %d\n", sum(results_df$p_bonferroni < 0.05), nrow(results_df)))

# ---- Visualization: Group comparison plots ----
# Create grouped bar/box plots for primary metrics
plots_group <- list()
plot_idx <- 0

for (m in primary_metrics) {
  for (v in seq_along(videos)) {
    col_name <- paste0(m, "_", videos[v])
    if (!col_name %in% names(full_data)) next
    
    plot_idx <- plot_idx + 1
    df_plot <- data.frame(
      value = full_data[[col_name]],
      group = full_data$dep_group_primary
    )
    df_plot <- df_plot[!is.na(df_plot$value), ]
    
    # Get p-value for annotation
    row_match <- results_df[results_df$metric == metric_labels[match(m, all_metrics)] & 
                              results_df$video == video_labels[v], ]
    p_text <- sprintf("p = %.3f\nd = %.2f", row_match$p_value, row_match$cohens_d)
    
    plots_group[[plot_idx]] <- ggplot(df_plot, aes(x = group, y = value, fill = group)) +
      geom_boxplot(alpha = 0.7, outlier.shape = NA) +
      geom_jitter(width = 0.15, alpha = 0.4, size = 1.2) +
      scale_fill_manual(values = c("Non-Depressed" = "lightblue", "Depressed" = "salmon")) +
      labs(title = paste0(video_labels[v]), y = metric_labels[match(m, all_metrics)], x = "") +
      annotate("text", x = 1.5, y = max(df_plot$value, na.rm=T), label = p_text, size = 2.5) +
      theme_minimal() + theme(legend.position = "none", 
                               plot.title = element_text(size = 9),
                               axis.title.y = element_text(size = 8))
  }
}

# Save in groups of 5 (one per metric)
for (m_idx in 1:3) {
  start <- (m_idx - 1) * 5 + 1
  end <- min(m_idx * 5, length(plots_group))
  if (start <= length(plots_group)) {
    g <- arrangeGrob(grobs = plots_group[start:end], ncol = 5,
                     top = metric_labels[m_idx])
    fname <- paste0("fig10_group_comparison_", primary_metrics[m_idx], ".png")
    ggsave(file.path(outdir, fname), g, width = 18, height = 4, dpi = 150)
    cat(sprintf("Saved: %s\n", fname))
  }
}

# Save results
write.csv(results_df, "analysis/output/phase4_results.csv", row.names = FALSE)
save(full_data, ht_merged, ht_all, survey, results_df, 
     file = "analysis/output/processed_data.RData")
cat("\nPhase 4 complete.\n")
