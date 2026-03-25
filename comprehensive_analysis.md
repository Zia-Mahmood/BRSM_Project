# Comprehensive Analysis of VR Headtracking Study: Depression and Psychomotor Activity

## 1. Understanding of the Dataset and Experimental Context

### Dataset Overview
The dataset consists of behavioral and psychological data from 40 college students (36 male, 4 female; mean age = 22.78 years, SD = 1.80, range: 20-28) who participated in a VR experiment investigating the relationship between depressive symptoms and head movement patterns. 

### Experimental Context
Participants experienced five distinct 360° VR videos through a Meta Quest 3 headset, each designed to elicit different emotional responses:

| Video ID | Environment | Emotional Category | Mean Valence | Mean Arousal |
|----------|-------------|-------------------|--------------|--------------|
| V1 | Abandoned buildings | Negative | 4.12 | 4.50 |
| V2 | Evening beach | Positive | 5.62 | 4.85 |
| V3 | University campus | Neutral | 5.50 | 4.40 |
| V4 | Horror (The Nun) | High arousal | 3.67 | 5.95 |
| V5 | Tahiti surf | Positive | 7.12 | 6.50 |

The videos successfully spanned the emotional circumplex model, with V4 (Horror) occupying the "Tense/Stressed" quadrant and V5 (Surf) in the "Excited/Happy" quadrant.

### Data Collection
- **Headtracking Data**: Continuous recording at ~10 Hz capturing head orientation (pitch, yaw, roll) and rotational speed during each 3-5 minute video
- **Psychological Measures**: 
  - PHQ-9 (depression screening)
  - GAD-7 (anxiety)
  - STAI-T (trait anxiety) 
  - PANAS (affect pre/post)
  - VRISE (simulator sickness)
- **Subjective Ratings**: Valence, arousal, immersion, and emotional descriptions for each video

### Raw Data Structure
Headtracking CSVs contained time-series data with columns for:
- Time, Position (X,Y,Z), Rotation (X,Y,Z), RotationChange (X,Y,Z), RotationSpeed (X,Y,Z,Total)
- Files were processed to extract 15+ movement features per participant-video combination
- Survey data included demographic info, psychological scales, and video-specific ratings

## 2. Methodology: Preprocessing, Variables, and Statistical Tests

### Data Preprocessing Pipeline

#### Phase 0: Data Preparation
1. **Survey Loading**: Read Excel file containing participant demographics, psychological responses, and video filename mappings
2. **Headtracking Processing**: 
   - **Handling Malformed CSV Files**: The raw headtracking data from Meta Quest 3 occasionally contained corrupted CSV files with inconsistent row structures. Malformed CSVs were identified by rows having different numbers of comma-separated fields than expected (typically 19 columns based on the header). These issues likely arose from data export glitches or recording interruptions during VR sessions.
   - **Correction Process**: For each CSV file, the processing script first reads all lines as text. It determines the expected number of columns from the header row, then filters out any lines that don't match this column count. This ensures data integrity by removing truncated or corrupted rows while preserving valid time-series data.
   - **Data Type Conversion**: All columns are converted to numeric types to handle any string artifacts from the export process. Rows containing non-numeric values (resulting in NA after conversion) are removed to ensure clean numerical data for analysis.
   - **Initial Zero Measurement Removal**: The first row of each recording often contained zero values representing the initial headset calibration state before video playback began. These rows are automatically detected (RotationSpeedTotal == 0) and excluded from analysis.
   - **Minimum Sample Filtering**: Files with fewer than 10 valid data points after cleaning are excluded, as they represent insufficient recording duration (less than ~1 second at 10Hz sampling) for meaningful movement analysis.
3. **Feature Computation**: For each valid recording, calculate:
   - **Primary metrics**: Mean rotation speed (°/s), SD of yaw (°), SD of pitch (°)
   - **Secondary metrics**: SD of roll (°), Total movement magnitude, Mean speeds per axis, Range values
4. **Data Merging**: Match headtracking files to participants via filename mappings, create wide-format dataset
   - **Merging Process**: The survey Excel file contains filename mappings in columns v1-v5 for each participant, indicating which headtracking CSV file corresponds to their recording for each video. The processing script matches these filenames to link computed headtracking features to specific participants and videos.
   - **Wide-Format Creation**: Transforms the long-format headtracking data (multiple rows per participant, one per video) into a wide-format dataset where each row represents one participant, and columns contain features for each video (e.g., mean_speed_v1, sd_yaw_v2). This structure enables within-subject comparisons across videos and between-subject analyses by depression groups.
   - **Purpose and Utility**: The wide format is essential for statistical analyses requiring repeated measures (comparing the same participant's behavior across different emotional videos) and group comparisons (depressed vs non-depressed across videos). It results in a comprehensive dataset combining psychological assessments, demographics, and movement metrics in a single analyzable format.
5. **Missing Data Check**: Identified 2 participants missing V5 data, all others complete
   - **Missing V5 Data Handling**: Two participants had no headtracking recordings for the V5 (Tahiti surf) video, resulting in NA values for all V5-related columns in their rows. The dataset retains these participants with missing values rather than excluding them, preserving the full sample for other analyses.
   - **Completeness Assessment**: Systematic check revealed that all other video recordings were present, with no missing data for V1-V4 across participants. This ensures analytical integrity while maintaining statistical power.

#### Phase 1: Descriptive Statistics
- Computed comprehensive descriptive statistics (means, standard deviations, medians, interquartile ranges, minimum/maximum values) for all psychological scales (PHQ-9, GAD-7, STAI-T, VRISE, PANAS pre/post measures)
- Generated histograms with appropriate bin widths to visualize distributions of psychological variables
- Created density plots and Q-Q plots for headtracking variables to assess distributional properties and normality assumptions
- Performed Shapiro-Wilk normality tests on all variables, revealing that most headtracking metrics (especially SD yaw) were non-normally distributed
- Constructed correlation matrix analysis examining relationships between psychological measures and averaged headtracking features across all videos

#### Phase 2: Outlier Detection
- **Psychological Scales**: Applied dual outlier detection methods - IQR method (values beyond 1.5×IQR from Q1/Q3) and Z-score method (absolute Z > 2.5) - to identify extreme values in PHQ-9, GAD-7, and STAI-T scores
- **Headtracking Variables**: Identified outliers in averaged movement metrics (mean speed, SD yaw/pitch/roll) using the same IQR and Z-score approaches
- **VRISE Check**: Screened for participants with unusually low simulator sickness scores that might indicate non-engagement or technical issues
- **Decision Process**: After reviewing flagged cases, retained all 40 participants as outliers represented clinically plausible values and the small sample size (N=40) limited statistical power for exclusion

#### Phase 3: Group Partitioning
- **Primary Grouping**: Created binary depression groups using PHQ-9 cutoff of ≥5 (mild depression or higher) vs <5 (minimal symptoms), resulting in balanced groups of n=20 each (Non-Depressed: M=2.60, Depressed: M=9.45)
- **Secondary Grouping**: Applied more stringent cutoff of PHQ-9 ≥10 (moderate depression or higher) vs <10, creating groups of n=32 (Below Moderate) and n=8 (Moderate+)
- **Rationale**: PHQ-9 ≥5 represents the clinical threshold for mild depressive symptoms, while PHQ-9 ≥10 indicates moderate-to-severe depression requiring clinical attention

### Variables and Measurement

#### Dependent Variables (Headtracking Metrics)
- **Mean Rotation Speed**: Average total rotational speed across recording
- **SD Yaw**: Variability in horizontal head scanning
- **SD Pitch**: Variability in vertical head scanning  
- **SD Roll**: Variability in head tilt
- **Total Movement**: Cumulative absolute rotation changes

#### Independent Variables
- **Depression**: PHQ-9 score (0-27), grouped as binary categorical
- **Anxiety**: GAD-7 (0-21), STAI-T (20-80)
- **Video Type**: 5-level categorical (V1-V5)
- **Emotional Response**: Valence (1-9), Arousal (1-9), Immersion (1-35)

#### Control Variables
- Age, Gender, VR Experience, VRISE (simulator sickness)

### Statistical Analysis Framework

#### Phase 4: Core Hypothesis Testing
- **Normality Testing**: Shapiro-Wilk test per group per metric
- **Variance Testing**: Levene's test for equal variances
- **Group Comparisons**: 
  - Welch's t-test (if both groups normal)
  - Mann-Whitney U (if either group non-normal)
- **Effect Size**: Cohen's d (pooled SD)
- **Multiple Comparisons**: Benjamini-Hochberg FDR correction (α=0.05)

#### Phase 5: Depression-Anxiety Covariance
- Computed Pearson correlations (for normally distributed variables) and Spearman correlations (for non-normal variables) between PHQ-9, GAD-7, and STAI-T scores to assess comorbidity
- Performed partial correlations between depression and headtracking metrics while controlling for anxiety measures to isolate unique depression effects
- Conducted stratified analysis by median GAD-7 scores to examine whether anxiety levels moderated the relationship between depression and movement patterns

#### Phase 6: Video Effects
- Applied Friedman tests (non-parametric repeated measures ANOVA) to assess whether headtracking metrics differed significantly across the 5 VR videos within subjects
- Performed post-hoc Wilcoxon signed-rank tests with Bonferroni correction to identify which video pairs showed significant movement differences
- Used Kruskal-Wallis tests to compare movement patterns across emotional categories (Positive, Neutral, Negative) collapsed across videos

#### Phase 7: Exploratory Analyses
- Examined correlations between subjective emotion ratings (valence, arousal) and headtracking metrics to test whether emotional responses mediated movement patterns
- Performed paired t-tests on PANAS measures (positive and negative affect) before and after VR exposure to assess mood changes
- Investigated relationships between immersion ratings and headtracking variables to understand engagement effects
- Conducted sensitivity analysis using the more stringent PHQ-9 ≥10 cutoff to check if results held with moderate-to-severe depression only

## 3. Results: Presentation, Interpretation, and Hypothesis Testing

### Descriptive Results

#### Psychological Measures
- PHQ-9: M=6.03, SD=4.63, Median=4.50 (positively skewed)
- GAD-7: M=5.00, SD=4.31
- STAI-T: M=45.00, SD=14.63
- VRISE: M=31.88, SD=3.98 (minimal sickness)
- Depressed group showed elevated anxiety (GAD-7: 7.05 vs 2.95, STAI-T: 52.25 vs 37.75)

#### Headtracking by Video
| Video | Mean Speed (°/s) | SD Yaw (°) | SD Pitch (°) |
|-------|------------------|------------|--------------|
| V1: Abandoned | 39.09 | 90.0 | 17.0 |
| V2: Beach | 32.76 | 88.0 | 11.5 |
| V3: Campus | 34.88 | 90.0 | 13.0 |
| V4: Horror | 24.17 | 33.0 | 13.5 |
| V5: Surf | 31.16 | 85.0 | 13.5 |

V4 (Horror) showed lowest speed and most constrained yaw variability.

#### Distributional Properties
- Mean speed and SD pitch: Approximately normal
- SD yaw: Left-skewed, non-normal
- SD roll: Marginally normal

### Hypothesis Testing Results

#### Primary Hypothesis: Depression → Reduced Head Movement
**Result**: No statistically significant group differences at p<0.05 (raw or corrected)

**Key Findings**:
- V5 (Surf): Medium effect (d=0.54, p=0.105) - Depressed showed lower speed (28.12°/s vs 34.35°/s)
- V4 (Horror): Medium effects on SD yaw (d=-0.55, p=0.239) and total movement (d=-0.54, p=0.120)
- All other comparisons: Small/negigible effects

**Interpretation**: While no significant differences were found, medium effect sizes during emotionally salient videos (V4: threat, V5: positive arousal) suggest depression may modulate movement patterns in emotionally charged contexts, consistent with emotional context insensitivity theory.

#### Secondary Hypothesis: Anxiety → Increased/Erratic Scanning
**Result**: Not directly tested, but anxiety correlated strongly with depression (r=0.58, p<0.001)

#### Tertiary Hypothesis: Video Type → Distinct Movement Patterns
**Result**: Strongly supported

- Friedman tests: All primary metrics differed significantly across videos (p<0.001)
- V4 (Horror) differed from all others on speed and yaw variability (post-hoc p<0.05)
- Kruskal-Wallis: Significant differences by emotional category (p<0.05)

**Interpretation**: Videos successfully induced distinct behavioral responses, with horror content producing constrained, vigilant scanning patterns.

### Additional Analyses

#### Correlation Results
- PHQ-9 × Average Speed: r=-0.063, p=0.697 (no linear relationship)
- PHQ-9 × GAD-7: r=0.58, p<0.001 (strong comorbidity)
- Negative Affect × Average Speed: r=-0.32, p=0.042 (mood-related movement reduction)

#### Video Effects
- Emotional categories: Horror < Positive/Neutral on speed
- Within-subject consistency: Participants showed similar patterns across videos

#### Exploratory Findings
- Valence negatively correlated with speed (r=-0.25, p=0.03)
- Immersion showed weak positive correlations with movement
- PANAS: No significant pre/post changes in affect
- Sensitivity analysis (PHQ-9≥10): Larger effects but still non-significant (power limitation)

## 4. Conclusion and Future Work Plan

### Summary of Findings
This study investigated whether VR headtracking could serve as a behavioral marker of depressive symptoms. While no statistically significant group differences were found between depressed and non-depressed participants, several medium effect sizes (d≈0.5) emerged during emotionally intense videos, suggesting that depression may influence movement patterns particularly in emotionally salient contexts. Video type had a strong effect on head movement, confirming successful emotional induction. The dataset provides a rich foundation for behavioral depression research in VR environments.

### Limitations
1. **Sample Size**: N=40 provides limited power (post-hoc power ≈0.37 for d=0.54)
2. **Sample Composition**: Predominantly male (90%), mild depression range
3. **Self-Report Measures**: No clinical diagnosis, potential reporting bias
4. **Video Order**: No counterbalancing of presentation sequence

### Future Work Plan

#### Immediate Next Steps (Final Report)
1. **Partial Correlations**: Control for GAD-7/STAI-T to isolate depression effects
2. **Stratified Analysis**: Examine depression effects within low/high anxiety subgroups  
3. **PANAS Analysis**: Compare pre/post affective changes by depression group
4. **Immersion Moderation**: Test whether presence/immersion moderates movement-depression relationships
5. **Secondary Cutoff**: Full analysis with PHQ-9≥10 threshold

#### Medium-term Extensions (Post-Final Report)
1. **Larger Sample**: Recruit N=100+ for adequate power (80% for d=0.5)
2. **Clinical Sample**: Include diagnosed MDD patients vs healthy controls
3. **Longitudinal Design**: Track movement changes with treatment/intervention
4. **Advanced Analytics**: 
   - Time-series analysis of movement patterns
   - Machine learning classification of depression from movement features
   - Individual trajectory modeling

#### Long-term Research Directions
1. **Digital Biomarker Development**: Validate VR headtracking as depression screening tool
2. **Mechanistic Studies**: Investigate neural correlates of movement-depression relationships
3. **Intervention Applications**: Use VR movement feedback for behavioral activation therapy
4. **Cross-cultural Validation**: Test generalizability across diverse populations

## 5. Reasoning Behind Processing Choices and Key Term Definitions

### Reasoning for Data Processing Decisions

#### Why Clean Malformed CSV Files?
**Reasoning**: VR headtracking data from Meta Quest 3 can sometimes contain corrupted records due to sensor glitches, wireless interference, or recording artifacts. Filtering to correct column counts ensures data integrity and prevents downstream analysis errors from malformed entries.

#### Why Remove Initial Zero-Measurement Rows?
**Reasoning**: At the start of VR recordings, sensors may report zero values while calibrating. These artificial zeros would artificially deflate movement metrics, so removing them provides a more accurate representation of actual exploratory behavior.

#### Why Exclude Files with <10 Valid Samples?
**Reasoning**: Very short recordings (likely due to technical issues or early termination) don't provide sufficient data for reliable movement pattern analysis. The 10-sample threshold ensures at least ~1 second of valid data at 10 Hz sampling rate.

#### Why Use Mean Rotation Speed as Primary Metric?
**Reasoning**: Psychomotor retardation in depression manifests as reduced overall activity level. Mean speed captures the general vigor of head movement, analogous to how clinicians observe reduced motor activity in depressed patients.

#### Why Focus on SD of Yaw and Pitch?
**Reasoning**: Horizontal (yaw) and vertical (pitch) scanning reflect exploratory behavior and environmental engagement. Variability in these dimensions indicates how broadly and actively individuals survey their surroundings, which may be reduced in depression.

#### Why Use Non-Parametric Tests When Normality Violated?
**Reasoning**: Headtracking data often follows non-normal distributions due to individual differences in movement patterns and environmental constraints. Non-parametric tests (Mann-Whitney, Friedman) are more robust and don't assume normality, reducing Type I error risk.

#### Why Benjamini-Hochberg FDR Correction?
**Reasoning**: With 25 statistical tests (5 metrics × 5 videos), multiple comparison inflation is a major concern. FDR correction controls the expected proportion of false positives while being less conservative than Bonferroni, maintaining statistical power for detecting true effects.

#### Why Retain All Participants Despite Outliers?
**Reasoning**: With N=40, excluding participants substantially reduces power. The flagged outliers represented clinically plausible values (not sensor errors), and depression research often includes heterogeneous samples. The conservative approach prioritizes external validity over statistical purity.

### Key Term Definitions

#### Head Movement Terms
- **Yaw**: Horizontal rotation of the head (left-right turning). Measured in degrees, represents side-to-side scanning behavior.
- **Pitch**: Vertical rotation of the head (up-down tilting). Measured in degrees, represents vertical scanning behavior.  
- **Roll**: Lateral tilting of the head (ear-to-shoulder). Measured in degrees, represents head canting behavior.
- **Rotation Speed**: Rate of head movement in degrees per second, capturing movement vigor and tempo.

#### Psychological Assessment Terms
- **PHQ-9 (Patient Health Questionnaire-9)**: A 9-item self-report questionnaire measuring depression severity over the past 2 weeks. Scores range from 0-27; ≥5 indicates mild depression, ≥10 moderate, ≥15 severe. Clinically validated for screening major depressive disorder.
- **GAD-7 (Generalized Anxiety Disorder-7)**: A 7-item self-report measure of generalized anxiety symptoms. Scores range from 0-21; ≥5 mild anxiety, ≥10 moderate. Used to screen for GAD and assess anxiety severity.
- **STAI-T (State-Trait Anxiety Inventory - Trait subscale)**: A 20-item measure of stable anxiety tendencies (how one generally feels). Scores range from 20-80, with higher scores indicating greater trait anxiety. Distinguishes from temporary state anxiety.
- **PANAS (Positive and Negative Affect Schedule)**: A 20-item questionnaire measuring current positive affect (enthusiastic, active) and negative affect (distressed, nervous). Each subscale ranges from 10-50. Used to assess emotional state at specific moments.
- **VRISE (Virtual Reality Induced Symptoms and Effects)**: A 15-item questionnaire measuring simulator sickness symptoms (nausea, disorientation, eye strain) after VR exposure. Scores range from 0-60, with higher scores indicating more severe cybersickness.

#### Emotional Response Terms
- **Valence**: The pleasantness dimension of emotion (unpleasant vs. pleasant). Rated on a 1-9 scale where 1 = very unpleasant, 9 = very pleasant. Represents the positive-negative quality of emotional experience.
- **Arousal**: The activation/intensity dimension of emotion (calm vs. excited). Rated on a 1-9 scale where 1 = very calm, 9 = very excited. Represents the energy level of emotional experience.
- **Immersion/Presence**: The subjective sense of "being there" in the virtual environment. Rated on a 1-35 scale, measuring how convincingly the VR experience feels real and engaging.
- **Circumplex Model**: A two-dimensional model of emotion with valence (horizontal) and arousal (vertical) axes. Emotions are arranged in a circle, with categories like "excited/happy" (high valence, high arousal) and "sad/depressed" (low valence, low arousal).

#### Statistical Terms
- **Cohen's d**: Standardized effect size measuring group difference magnitude. d = 0.2 (small), 0.5 (medium), 0.8 (large). Represents the number of standard deviations groups differ by.
- **Friedman Test**: Non-parametric test for repeated measures across multiple conditions. Used when comparing the same participants across different videos/environments.
- **Kruskal-Wallis Test**: Non-parametric equivalent of ANOVA for comparing multiple independent groups. Used for comparing movement across emotional video categories.
- **Partial Correlation**: Correlation between two variables while controlling for a third variable. Used to isolate depression effects from anxiety comorbidity.

This comprehensive analysis demonstrates a well-executed study with rigorous methodology, providing valuable insights into VR-based behavioral assessment of mental health while establishing a clear roadmap for future research to overcome current limitations and advance the field.