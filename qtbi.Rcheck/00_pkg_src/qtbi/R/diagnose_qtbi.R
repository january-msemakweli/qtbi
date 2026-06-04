#' Diagnose QTBI encoder behavior on processed data
#'
#' @param data A `qtbi_data` object from [estimate_qtbi()].
#' @param synergy_grid Grid of synergy values for sensitivity curves.
#' @param synergy_ref Reference synergy for summary statistics (defaults to
#'   the value used in [estimate_qtbi()]).
#' @param verbose If `TRUE`, print a concise summary.
#'
#' @return A `qtbi_diagnosis` object (also printed when `verbose = TRUE`).
#' @export
diagnose_qtbi <- function(
    data,
    synergy_grid = seq(0, 1, by = 0.05),
    synergy_ref = NULL,
    verbose = TRUE
) {
  meta <- qtbi_meta(data)
  if (is.null(synergy_ref)) {
    synergy_ref <- meta$synergy_strength
  }

  diag <- synergy_diagnostics(
    .pct_matrix_from_qtbi_data(data),
    synergy_grid = synergy_grid,
    synergy_ref = synergy_ref,
    exposure_names = meta$exposure_names,
    weights = meta$potency_weights
  )

  if (verbose) {
    print(diag)
  }
  invisible(diag)
}

#' @export
print.qtbi_diagnosis <- function(x, ...) {
  mono <- x$monotonicity
  cat("QTBI encoder diagnostics\n")
  cat("  Subjects:                    ", mono$n_subjects, "\n", sep = "")
  cat("  Monotone over synergy grid:  ", sprintf("%.1f%%", mono$pct_monotone_full_grid),
      " (", mono$n_violations_full_grid, " violations)\n", sep = "")
  cat("  QTBI >= additive at s_ref:   ", sprintf("%.1f%%", mono$pct_qtbi_at_ref_ge_additive), "\n", sep = "")
  cat("  Median profile monotone:     ", mono$median_profile_monotone, "\n", sep = "")
  cat("  Reference synergy (s_ref):   ", mono$synergy_ref, "\n", sep = "")
  if (!is.null(x$potency_weights)) {
    cat("  Potency weights:             weighted readout\n")
  }
  invisible(x)
}
