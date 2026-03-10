###############################################################################
# Phase 0: Data Preparation & Preprocessing
###############################################################################

library(readxl)
library(dplyr)
library(tidyr)

# Set working directory
setwd("C:/Users/123ad/Downloads/SEM-4/BRSM/VR")

# ---- 0.1 Load survey data ----
survey <- read_excel("data/data.xlsx")
cat("Survey data loaded:", nrow(survey), "participants x", ncol(survey), "columns\n")

# ---- 0.2 & 0.3 Load and process headtracking CSVs ----
compute_ht_features <- function(filepath) {
  # Read lines and filter to correct number of fields
  lines <- readLines(filepath, warn = FALSE)
  header <- strsplit(lines[1], ",")[[1]]
  ncols <- length(header)
  good_lines <- lines[sapply(lines, function(l) length(strsplit(l, ",")[[1]]) == ncols)]
  tc <- textConnection(paste(good_lines, collapse = "\n"))
  df <- read.csv(tc, header = TRUE, stringsAsFactors = FALSE)
  close(tc)
  
  # Ensure all columns are numeric
  for (col in names(df)) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }
  df <- df[complete.cases(df), ]
  
  if (nrow(df) < 10) return(NULL)
  
  # Remove first row if it's the initial zero-measurement
  if (df$RotationSpeedTotal[1] == 0) df <- df[-1, ]
  
  data.frame(
    # Primary metrics
    mean_speed        = mean(df$RotationSpeedTotal, na.rm = TRUE),
    sd_pitch          = sd(df$RotationChangeX, na.rm = TRUE),
    sd_yaw            = sd(df$RotationChangeY, na.rm = TRUE),
    sd_roll           = sd(df$RotationChangeZ, na.rm = TRUE),
    # Secondary metrics
    mean_pitch        = mean(df$RotationChangeX, na.rm = TRUE),
    mean_yaw          = mean(df$RotationChangeY, na.rm = TRUE),
    mean_roll         = mean(df$RotationChangeZ, na.rm = TRUE),
    range_pitch       = diff(range(df$RotationChangeX, na.rm = TRUE)),
    range_yaw         = diff(range(df$RotationChangeY, na.rm = TRUE)),
    range_roll        = diff(range(df$RotationChangeZ, na.rm = TRUE)),
    mean_speed_x      = mean(df$RotationSpeedX, na.rm = TRUE),
    mean_speed_y      = mean(df$RotationSpeedY, na.rm = TRUE),
    mean_speed_z      = mean(df$RotationSpeedZ, na.rm = TRUE),
    # Total movement magnitude
    total_movement    = sum(abs(df$RotationChangeX) + abs(df$RotationChangeY) + abs(df$RotationChangeZ), na.rm = TRUE),
    # Recording info
    n_samples         = nrow(df),
    duration          = max(df$Time, na.rm = TRUE) - min(df$Time, na.rm = TRUE)
  )
}

# Process all videos
videos <- c("v1", "v2", "v3", "v4", "v5")
video_nums <- 1:5
ht_all <- data.frame()

for (i in seq_along(videos)) {
  v <- videos[i]
  vn <- video_nums[i]
  dir_path <- paste0("data/headtracking-data/", v)
  
  if (!dir.exists(dir_path)) {
    cat("Directory not found:", dir_path, "\n")
    next
  }
  
  files <- list.files(dir_path, pattern = "\\.csv$", full.names = TRUE)
  cat("Processing", v, ":", length(files), "files\n")
  
  for (f in files) {
    fname <- basename(f)
    features <- compute_ht_features(f)
    if (!is.null(features)) {
      features$video <- v
      features$filename <- fname
      ht_all <- rbind(ht_all, features)
    } else {
      cat("  WARNING: Could not process", fname, "\n")
    }
  }
}

cat("\nHeadtracking features computed:", nrow(ht_all), "rows\n")

# ---- 0.4 Merge with survey data ----
# Match headtracking files to participants via the v1...v5 columns in survey
# Survey has columns v1, v2, v3, v4, v5 with filenames

ht_merged <- data.frame()
for (v in videos) {
  # Get the filenames from survey for this video
  survey_fnames <- survey[[v]]
  ht_video <- ht_all[ht_all$video == v, ]
  
  for (p in 1:nrow(survey)) {
    fname <- survey_fnames[p]
    if (is.na(fname) || fname == "") next
    
    match_row <- ht_video[ht_video$filename == fname, ]
    if (nrow(match_row) == 1) {
      match_row$participant <- survey$participant[p]
      match_row$participant_idx <- p
      ht_merged <- rbind(ht_merged, match_row)
    } else {
      cat("  No match for participant", p, "video", v, "file:", fname, "\n")
    }
  }
}

cat("Merged headtracking rows:", nrow(ht_merged), "\n")

# Create wide format: one row per participant with headtracking features per video
ht_wide <- ht_merged %>%
  select(participant_idx, video, mean_speed, sd_pitch, sd_yaw, sd_roll,
         mean_pitch, mean_yaw, mean_roll, total_movement,
         mean_speed_x, mean_speed_y, mean_speed_z,
         range_pitch, range_yaw, range_roll, n_samples, duration) %>%
  pivot_wider(
    id_cols = participant_idx,
    names_from = video,
    values_from = c(mean_speed, sd_pitch, sd_yaw, sd_roll,
                    mean_pitch, mean_yaw, mean_roll, total_movement,
                    mean_speed_x, mean_speed_y, mean_speed_z,
                    range_pitch, range_yaw, range_roll, n_samples, duration),
    names_sep = "_"
  )

# Merge with survey
survey$participant_idx <- 1:nrow(survey)
full_data <- merge(survey, ht_wide, by = "participant_idx", all.x = TRUE)

cat("\nFinal merged dataset:", nrow(full_data), "rows x", ncol(full_data), "columns\n")

# ---- 0.5 Missing data check ----
cat("\n===== MISSING DATA CHECK =====\n")
missing_counts <- colSums(is.na(full_data))
missing_nonzero <- missing_counts[missing_counts > 0]
if (length(missing_nonzero) > 0) {
  cat("Variables with missing values:\n")
  for (nm in names(missing_nonzero)) {
    cat(sprintf("  %-40s: %d / %d (%.1f%%)\n", nm, missing_nonzero[nm], 
                nrow(full_data), 100 * missing_nonzero[nm] / nrow(full_data)))
  }
} else {
  cat("No missing values found.\n")
}

# Check headtracking completeness
cat("\nHeadtracking data availability per video:\n")
for (v in videos) {
  col <- paste0("mean_speed_", v)
  if (col %in% names(full_data)) {
    n_avail <- sum(!is.na(full_data[[col]]))
    cat(sprintf("  %s: %d / %d participants\n", v, n_avail, nrow(full_data)))
  }
}

# ---- Save processed data ----
dir.create("analysis/output", recursive = TRUE, showWarnings = FALSE)
save(full_data, ht_merged, ht_all, survey, file = "analysis/output/processed_data.RData")
write.csv(full_data, "analysis/output/full_data.csv", row.names = FALSE)
cat("\nData saved to analysis/output/\n")

# Print summary of key variables
cat("\n===== KEY VARIABLE SUMMARIES =====\n")
cat("\nPHQ-9 scores:\n")
print(summary(full_data$score_phq))
cat("\nGAD-7 scores:\n")
print(summary(full_data$score_gad))
cat("\nSTAI-T scores:\n")
print(summary(full_data$score_stai_t))
cat("\nVRISE scores:\n")
print(summary(full_data$score_vrise))
cat("\nAge:\n")
print(summary(full_data$age))
cat("\nGender (1=M, 2=F):\n")
print(table(full_data$gender))

# Print headtracking summary per video
cat("\n===== HEADTRACKING SUMMARY PER VIDEO =====\n")
for (v in videos) {
  col <- paste0("mean_speed_", v)
  if (col %in% names(full_data)) {
    cat(sprintf("\n%s - Mean Rotation Speed: M=%.2f, SD=%.2f, Med=%.2f\n",
                toupper(v), 
                mean(full_data[[col]], na.rm = TRUE),
                sd(full_data[[col]], na.rm = TRUE),
                median(full_data[[col]], na.rm = TRUE)))
  }
}
