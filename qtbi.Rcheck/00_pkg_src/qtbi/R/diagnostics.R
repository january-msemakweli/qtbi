#' Synergy sensitivity on cohort median percentiles
#'
#' @param pct_mat Numeric matrix of within-cohort percentiles.
#' @param synergy_grid Grid of synergy values in `[0, 1]`.
#' @param weights Optional potency weights aligned with columns of `pct_mat`.
#' @return Data frame with synergy, qtbi, and additive_baseline columns.
#' @export
synergy_sensitivity <- function(
    pct_mat,
    synergy_grid = seq(0, 1, by = 0.05),
    weights = NULL
) {
  pct_mat <- as.matrix(pct_mat)
  ref <- apply(pct_mat, 2, stats::median, na.rm = TRUE)
  data.frame(
    synergy = synergy_grid,
    qtbi = vapply(
      synergy_grid,
      function(s) qtbi_from_vector(ref, s, weights = weights),
      numeric(1)
    ),
    additive_baseline = .additive_burden(ref, weights)
  )
}

#' Full circuit diagnostics for a cohort percentile matrix
#'
#' @param pct_mat Numeric matrix of within-cohort percentiles (rows = subjects).
#' @param synergy_grid Grid of synergy values in `[0, 1]`.
#' @param synergy_ref Reference synergy for summary statistics.
#' @param exposure_names Labels for exposures (columns of `pct_mat`).
#' @param metal_names Deprecated alias for `exposure_names`.
#' @param weights Optional potency weights aligned with columns of `pct_mat`.
#' @return List with cohort_band, marginals, monotonicity, synergy_ref, sens_ref.
#' @export
synergy_diagnostics <- function(
    pct_mat,
    synergy_grid = seq(0, 1, by = 0.05),
    synergy_ref = 0.6,
    exposure_names = NULL,
    metal_names = NULL,
    weights = NULL
) {
  if (!is.null(metal_names)) {
    exposure_names <- metal_names
  }
  pct_mat <- as.matrix(pct_mat)
  n_sub <- nrow(pct_mat)
  if (is.null(exposure_names)) {
    exposure_names <- colnames(pct_mat)
  }
  if (is.null(exposure_names)) {
    exposure_names <- paste0("E", seq_len(ncol(pct_mat)))
  }

  additive <- if (is.null(weights)) {
    rowSums(pct_mat)
  } else {
    pct_mat %*% weights
  }
  ref <- apply(pct_mat, 2, stats::median, na.rm = TRUE)

  qtbi_mat <- matrix(NA_real_, n_sub, length(synergy_grid))
  band_rows <- vector("list", length(synergy_grid))
  for (i in seq_along(synergy_grid)) {
    s <- synergy_grid[[i]]
    qtbi <- qtbi_from_pcts(pct_mat, synergy = s, weights = weights)
    qtbi_mat[, i] <- qtbi
    band_rows[[i]] <- data.frame(
      synergy = s,
      qtbi_p05 = unname(stats::quantile(qtbi, 0.05)),
      qtbi_p25 = unname(stats::quantile(qtbi, 0.25)),
      qtbi_p50 = unname(stats::quantile(qtbi, 0.50)),
      qtbi_p75 = unname(stats::quantile(qtbi, 0.75)),
      qtbi_p95 = unname(stats::quantile(qtbi, 0.95)),
      additive_p50 = unname(stats::median(additive))
    )
  }
  cohort_band <- do.call(rbind, band_rows)

  monotone <- apply(qtbi_mat, 1, function(row) all(diff(row) >= -1e-10))
  qtbi_s0 <- qtbi_mat[, 1L]
  ref_idx <- which.min(abs(synergy_grid - synergy_ref))
  qtbi_ref <- qtbi_mat[, ref_idx]
  ref_curve <- vapply(
    synergy_grid,
    function(s) qtbi_from_vector(ref, s, weights = weights),
    numeric(1)
  )

  monotonicity <- data.frame(
    n_subjects = n_sub,
    pct_monotone_full_grid = 100 * mean(monotone),
    n_violations_full_grid = sum(!monotone),
    pct_qtbi_at_ref_ge_additive = 100 * mean(qtbi_ref >= qtbi_s0 - 1e-10),
    median_profile_monotone = all(diff(ref_curve) >= -1e-10),
    synergy_ref = synergy_ref
  )

  marg_rows <- vector("list", length(synergy_grid))
  for (i in seq_along(synergy_grid)) {
    s <- synergy_grid[[i]]
    m <- marginal_toxic_probs(build_statevector(ref, s))
    marg_rows[[i]] <- data.frame(
      synergy = s,
      exposure = exposure_names,
      metal = exposure_names,
      marginal = m,
      percentile = ref
    )
  }
  marginals <- do.call(rbind, marg_rows)

  structure(
    list(
      cohort_band = cohort_band,
      marginals = marginals,
      monotonicity = monotonicity,
      synergy_ref = synergy_ref,
      sens_ref = synergy_sensitivity(
        pct_mat,
        synergy_grid = synergy_grid,
        weights = weights
      ),
      exposure_names = exposure_names,
      potency_weights = weights
    ),
    class = "qtbi_diagnosis"
  )
}

.pct_matrix_from_qtbi_data <- function(data) {
  meta <- qtbi_meta(data)
  as.matrix(data[, meta$pct_cols, drop = FALSE])
}
