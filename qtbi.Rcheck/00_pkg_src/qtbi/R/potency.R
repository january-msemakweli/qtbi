#' Derive relative potency weights from reference doses
#'
#' Computes outcome-independent weights as the ratio of the index chemical
#' reference dose to each component reference dose:
#' \deqn{w_i = \mathrm{RfD}_{\mathrm{index}} / \mathrm{RfD}_i}
#'
#' Lower reference doses (more potent toxicants) receive larger weights.
#'
#' @param reference_doses Named numeric vector of oral reference doses in
#'   mg/kg/day, with one value per exposure in `chemicals`.
#' @param chemicals Character vector of exposure identifiers in panel order.
#'   Names must match `names(reference_doses)`.
#' @param reference_index Name of the index chemical. Defaults to the first
#'   entry in `chemicals`.
#'
#' @return Named numeric vector of potency weights aligned with `chemicals`.
#' @export
potency_weights_from_reference_doses <- function(
    reference_doses,
    chemicals,
    reference_index = NULL
) {
  if (is.null(reference_doses)) {
    return(NULL)
  }
  if (length(chemicals) < 1L) {
    stop("`chemicals` must contain at least one exposure.", call. = FALSE)
  }
  if (is.null(names(reference_doses)) || any(names(reference_doses) == "")) {
    stop("`reference_doses` must be a named numeric vector.", call. = FALSE)
  }

  ref <- reference_doses[chemicals]
  if (any(is.na(ref))) {
    miss <- chemicals[is.na(ref)]
    stop(
      "Missing reference doses for: ", paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  ref <- as.numeric(ref)
  names(ref) <- chemicals
  if (any(!is.finite(ref)) || any(ref <= 0)) {
    stop("`reference_doses` must be finite and positive.", call. = FALSE)
  }

  if (is.null(reference_index)) {
    reference_index <- chemicals[[1L]]
  }
  if (!reference_index %in% chemicals) {
    stop(
      "`reference_index` must appear in `chemicals`.",
      call. = FALSE
    )
  }

  idx_ref <- ref[[reference_index]]
  weights <- idx_ref / ref
  names(weights) <- chemicals
  weights
}

#' Rescale potency weights to match the unweighted QTBI scale
#'
#' When potency weights are applied at readout, rescale them so their sum equals
#' the number of exposures in the panel. This keeps weighted QTBI on the same
#' \eqn{[0, n]} scale as the unweighted sum of marginals, which aids comparison
#' between weighted and unweighted analyses.
#'
#' @param weights Named numeric vector of raw potency ratios from
#'   [potency_weights_from_reference_doses()].
#' @param target_sum Target sum for the rescaled weights. Defaults to the
#'   number of exposures (`length(weights)`).
#'
#' @return Named numeric vector of rescaled weights aligned with `weights`.
#' @export
normalize_potency_weights <- function(weights, target_sum = NULL) {
  if (is.null(weights)) {
    return(NULL)
  }
  if (length(weights) < 1L) {
    stop("`weights` must contain at least one value.", call. = FALSE)
  }
  w <- as.numeric(weights)
  names(w) <- names(weights)
  if (any(!is.finite(w)) || any(w <= 0)) {
    stop("`weights` must be finite and positive.", call. = FALSE)
  }
  if (is.null(target_sum)) {
    target_sum <- length(weights)
  }
  target_sum <- as.numeric(target_sum)[1L]
  if (!is.finite(target_sum) || target_sum <= 0) {
    stop("`target_sum` must be a positive finite number.", call. = FALSE)
  }
  w * target_sum / sum(w)
}

.resolve_reference_doses <- function(reference_doses, chemicals, exposure_names) {
  if (is.null(reference_doses)) {
    return(NULL)
  }
  labels <- if (!is.null(exposure_names)) exposure_names else chemicals
  if (is.null(names(reference_doses)) || any(names(reference_doses) == "")) {
    stop(
      "`reference_doses` must be a named numeric vector aligned with ",
      "`exposure_names` or `chemicals`.",
      call. = FALSE
    )
  }
  ref <- reference_doses[labels]
  if (any(is.na(ref))) {
    miss <- labels[is.na(ref)]
    stop(
      "Missing reference doses for: ", paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  stats::setNames(as.numeric(ref), labels)
}

.additive_burden <- function(pct_row, weights = NULL) {
  pct_row <- as.numeric(pct_row)
  if (is.null(weights)) {
    return(sum(pct_row))
  }
  sum(weights * pct_row)
}
