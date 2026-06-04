#' Estimate QTBI and append scores to a data frame
#'
#' Computes within-cohort exposure percentiles, runs the fixed entanglement
#' encoder, and returns the input data with percentile and QTBI columns added.
#'
#' @param data A data frame containing exposure columns.
#' @param chemicals Character vector of exposure column names.
#' @param synergy_strength Synergy strength in `[0, 1]`.
#' @param qtbi_col Name for the QTBI score column (default `"qtbi"`).
#' @param percentile_prefix Prefix for percentile columns (default `"pct_"`).
#' @param pct_cols Optional percentile column names (same length as `chemicals`).
#' @param exposure_names Optional display names for plots (defaults to `chemicals`).
#' @param reference_doses Optional named numeric vector of oral reference doses
#'   in mg/kg/day, with names matching `exposure_names` (or `chemicals` if
#'   `exposure_names` is omitted). The package derives potency weights as
#'   `reference_index` dose divided by each component dose, rescales them so
#'   their sum equals the number of exposures (keeping QTBI on the same
#'   \eqn{[0, n]} scale as the unweighted index), and applies them at readout only.
#' @param reference_index Name of the index chemical for potency ratios. Defaults
#'   to the first `exposure_names` entry (or first `chemicals` entry).
#'
#' @return A `qtbi_data` object (data frame) with QTBI and percentile columns.
#' @export
#'
#' @examples
#' df <- data.frame(
#'   Pb = c(1, 2, 3, 4),
#'   As = c(4, 3, 2, 1),
#'   Cd = c(2, 2, 3, 3),
#'   Hg = c(1, 3, 2, 4)
#' )
#' out <- estimate_qtbi(
#'   df,
#'   chemicals = c("Pb", "As", "Cd", "Hg"),
#'   synergy_strength = 0.6,
#'   reference_doses = c(Pb = 6.3e-4, As = 6.0e-5, Cd = 5.0e-4, Hg = 1.0e-4),
#'   reference_index = "Pb"
#' )
#' out$qtbi
estimate_qtbi <- function(
    data,
    chemicals,
    synergy_strength = 0.6,
    qtbi_col = "qtbi",
    percentile_prefix = "pct_",
    exposure_names = NULL,
    pct_cols = NULL,
    reference_doses = NULL,
    reference_index = NULL
) {
  synergy_strength <- as.numeric(synergy_strength)[1L]
  if (!is.finite(synergy_strength) || synergy_strength < 0 || synergy_strength > 1) {
    stop("`synergy_strength` must be in [0, 1].", call. = FALSE)
  }

  .check_chemical_cols(data, chemicals)
  pct_mat <- percentile_matrix(data, chemicals)
  if (is.null(pct_cols)) {
    pct_cols <- vapply(
      chemicals,
      function(c) paste0(percentile_prefix, make.names(c, unique = TRUE)),
      character(1)
    )
  } else if (length(pct_cols) != length(chemicals)) {
    stop("`pct_cols` must have the same length as `chemicals`.", call. = FALSE)
  }

  if (is.null(exposure_names)) {
    exposure_names <- chemicals
  }

  ref_doses <- .resolve_reference_doses(reference_doses, chemicals, exposure_names)
  potency_weights <- NULL
  potency_weights_raw <- NULL
  if (!is.null(ref_doses)) {
    if (is.null(reference_index)) {
      reference_index <- exposure_names[[1L]]
    }
    potency_weights_raw <- potency_weights_from_reference_doses(
      ref_doses,
      exposure_names,
      reference_index = reference_index
    )
    potency_weights <- normalize_potency_weights(
      potency_weights_raw,
      target_sum = length(chemicals)
    )
  }

  out <- data
  for (j in seq_along(chemicals)) {
    out[[pct_cols[[j]]]] <- pct_mat[, j]
  }
  out[[qtbi_col]] <- qtbi_from_pcts(
    pct_mat,
    synergy = synergy_strength,
    weights = potency_weights
  )

  attr(out, "qtbi") <- list(
    chemicals = chemicals,
    exposure_names = exposure_names,
    pct_cols = pct_cols,
    qtbi_col = qtbi_col,
    synergy_strength = synergy_strength,
    n_exposures = length(chemicals),
    reference_doses = ref_doses,
    reference_index = reference_index,
    potency_weights_raw = potency_weights_raw,
    potency_weights = potency_weights,
    weighted = !is.null(potency_weights)
  )
  class(out) <- unique(c("qtbi_data", class(out)))
  out
}
