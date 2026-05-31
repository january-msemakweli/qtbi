#!/usr/bin/env Rscript
# Minimal NHANES illustration: QTBI encoding + adjusted logistic regression.
#
# Usage:
#   Rscript illustration/nhanes_ckd_illustration.R
#   Rscript illustration/nhanes_ckd_illustration.R --data=path/to/nhanes_qtbi.csv
#   source("illustration/nhanes_ckd_illustration.R")   # also supported

get_script_dir <- function() {
  cmd <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd, value = TRUE)
  if (length(file_arg)) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))))
  }
  for (i in rev(seq_len(sys.nframe()))) {
    ofile <- sys.frame(i)$ofile
    if (!is.null(ofile) && nzchar(ofile)) {
      return(dirname(normalizePath(ofile)))
    }
  }
  "."
}

args <- commandArgs(trailingOnly = TRUE)
data_path <- file.path(get_script_dir(), "data", "nhanes_qtbi.csv")
if ("--data" %in% args) {
  idx <- which(args == "--data")
  if (length(idx) && idx < length(args)) {
    data_path <- args[[idx + 1L]]
  }
}

suppressPackageStartupMessages({
  library(qtbi)
  library(dplyr)
  library(readr)
})

synergy <- 0.6
metal_names <- c("Pb", "As", "Cd", "Hg")
exposure_cols <- c("LBXBPB", "URXIAS", "LBXBCD", "LBXTHG")
reg_cols <- c(exposure_cols, "ckd", "RIDAGEYR", "RIAGENDR", "RIDRETH3")
reference_doses <- c(Pb = 6.3e-4, As = 6.0e-5, Cd = 5.0e-4, Hg = 1.0e-4)

is_female <- function(x) {
  if (is.numeric(x)) return(as.integer(x == 2))
  as.integer(tolower(as.character(x)) == "female")
}

race_indicators <- function(ridreth3) {
  s <- tolower(as.character(ridreth3))
  data.frame(
    race_MexAm = as.integer(grepl("mexican american", s)),
    race_OthHisp = as.integer(grepl("other hispanic", s)),
    race_NHBlack = as.integer(grepl("non-hispanic black", s)),
    race_NHAsian = as.integer(grepl("non-hispanic asian", s)),
    race_Other = as.integer(grepl("other race", s)),
    check.names = FALSE
  )
}

covariate_names <- function() {
  c("age", "age2", "female", "race_MexAm", "race_OthHisp",
    "race_NHBlack", "race_NHAsian", "race_Other")
}

add_covariates <- function(df) {
  cbind(
    df,
    data.frame(
      age = df$RIDAGEYR,
      age2 = df$RIDAGEYR^2 / 100,
      female = is_female(df$RIAGENDR),
      race_indicators(df$RIDRETH3),
      check.names = FALSE
    )
  )
}

print_or <- function(fit, term) {
  sm <- summary(fit)$coefficients
  ci <- confint.default(fit)
  if (!term %in% rownames(sm)) return(invisible(NULL))
  cat(sprintf(
    "  %s: OR = %.2f (95%% CI %.2f to %.2f), p = %.4f\n",
    term,
    exp(coef(fit)[[term]]),
    exp(ci[term, 1L]),
    exp(ci[term, 2L]),
    sm[term, "Pr(>|z|)"]
  ))
}

fit_logistic <- function(df, qtbi) {
  cov <- covariate_names()
  model_df <- data.frame(ckd = df$ckd, qtbi = qtbi, df[, cov, drop = FALSE])
  rhs <- paste(c("qtbi", cov), collapse = " + ")
  glm(as.formula(paste("ckd ~", rhs)), data = model_df, family = binomial())
}

fit_quartile_logistic <- function(df, qtbi) {
  cov <- covariate_names()
  br <- unique(quantile(qtbi, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE))
  qtbi_q <- cut(
    qtbi, breaks = br, include.lowest = TRUE,
    labels = c("Q1", "Q2", "Q3", "Q4")
  )
  model_df <- data.frame(
    ckd = df$ckd,
    qtbi_q = factor(qtbi_q, levels = c("Q1", "Q2", "Q3", "Q4")),
    df[, cov, drop = FALSE]
  )
  rhs <- paste(c("qtbi_q", cov), collapse = " + ")
  glm(as.formula(paste("ckd ~", rhs)), data = model_df, family = binomial())
}

if (!file.exists(data_path)) {
  stop(
    "Missing analytic file: ", data_path,
    ". See illustration/README.md for required columns.",
    call. = FALSE
  )
}

df <- read_csv(data_path, show_col_types = FALSE) %>%
  filter(if_all(all_of(reg_cols), ~ !is.na(.)))
df <- add_covariates(df)

cat("=== NHANES CKD illustration (minimal) ===\n\n")
cat("Data:", normalizePath(data_path, mustWork = FALSE), "\n")
cat("Cohort n =", nrow(df), "  CKD prevalence =",
    sprintf("%.1f%%", 100 * mean(df$ckd)), "\n\n")

cat("Stage 1: QTBI encoding (synergy s =", synergy, ")\n")
processed_unw <- estimate_qtbi(
  df,
  chemicals = exposure_cols,
  exposure_names = metal_names,
  synergy_strength = synergy
)
processed_wgt <- estimate_qtbi(
  df,
  chemicals = exposure_cols,
  exposure_names = metal_names,
  synergy_strength = synergy,
  reference_doses = reference_doses,
  reference_index = "Pb"
)

cat("  Unweighted QTBI range: [",
    sprintf("%.3f", min(processed_unw$qtbi)), ", ",
    sprintf("%.3f", max(processed_unw$qtbi)), "]\n", sep = "")
cat("  Weighted QTBI range: [",
    sprintf("%.3f", min(processed_wgt$qtbi)), ", ",
    sprintf("%.3f", max(processed_wgt$qtbi)), "]\n\n", sep = "")

cat("Stage 2: adjusted logistic regression\n\n")
for (label in c("Unweighted", "Weighted")) {
  qtbi <- if (label == "Unweighted") processed_unw$qtbi else processed_wgt$qtbi
  cat(label, "QTBI — continuous model\n")
  print_or(fit_logistic(df, qtbi), "qtbi")
  cat(label, "QTBI — quartile model (Q1 reference)\n")
  fit_q <- fit_quartile_logistic(df, qtbi)
  for (term in c("qtbi_qQ2", "qtbi_qQ3", "qtbi_qQ4")) {
    print_or(fit_q, term)
  }
  cat("\n")
}

cat("Done.\n")
