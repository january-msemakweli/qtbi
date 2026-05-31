#' Build the n-qubit entanglement statevector for one subject
#'
#' @param percentiles Numeric vector of exposure percentiles in `[0, 1]`.
#' @param synergy Synergy strength in `[0, 1]`.
#' @return Complex statevector of length `2^n`.
#' @export
build_statevector <- function(percentiles, synergy = 0.6) {
  n <- length(percentiles)
  if (n < 1L) stop("`percentiles` must contain at least one value.", call. = FALSE)
  state <- rep(0, 2L^n)
  state[[1]] <- 1 + 0i
  for (i in seq_len(n)) {
    state <- .apply_ry(state, .theta(percentiles[[i]]), i - 1L, n)
  }
  if (synergy > 0) {
    s <- synergy * pi / 2
    edges <- .synergy_edges(n)
    if (nrow(edges) > 0) {
      for (i in seq_len(nrow(edges))) {
        state <- .apply_cry(
          state, s * edges[i, 3],
          as.integer(edges[i, 1]),
          as.integer(edges[i, 2]), n
        )
      }
    }
    for (tr in .synergy_triples(n)) {
      state <- .apply_ccry(state, s * tr$w, tr$ctrls, tr$tgt, n)
    }
  }
  state
}

#' Marginal toxic probabilities from a QTBI statevector
#'
#' @param state Complex statevector from [build_statevector()].
#' @return Numeric vector of marginal toxic probabilities.
#' @export
marginal_toxic_probs <- function(state) {
  probs <- Re(state * Conj(state))
  n <- as.integer(log2(length(probs)))
  vapply(seq_len(n) - 1L, function(q) {
    mask <- vapply(seq_along(probs) - 1L, .bit, logical(1), q = q)
    sum(probs[mask])
  }, numeric(1))
}

#' Compute QTBI from a statevector
#'
#' @param state Complex statevector from [build_statevector()].
#' @param weights Optional named numeric potency weights aligned with qubits.
#'   When `NULL`, marginals are summed with equal weight.
#' @return Scalar QTBI score (sum of marginal toxic probabilities).
#' @export
qtbi_from_state <- function(state, weights = NULL) {
  marg <- marginal_toxic_probs(state)
  if (is.null(weights)) {
    return(sum(marg))
  }
  if (length(weights) != length(marg)) {
    stop("`weights` length must match the number of qubits.", call. = FALSE)
  }
  sum(weights * marg)
}

#' Compute QTBI from percentile matrix
#'
#' @param pct_mat Numeric matrix of within-cohort percentiles (rows = subjects).
#' @param synergy Synergy strength in `[0, 1]`.
#' @param weights Optional named numeric potency weights aligned with columns.
#' @return Numeric vector of QTBI scores.
#' @export
qtbi_from_pcts <- function(pct_mat, synergy = 0.6, weights = NULL) {
  pct_mat <- as.matrix(pct_mat)
  vapply(seq_len(nrow(pct_mat)), function(i) {
    qtbi_from_state(build_statevector(pct_mat[i, ], synergy), weights = weights)
  }, numeric(1))
}

#' Compute QTBI from one percentile vector
#'
#' @param pct_vec Numeric vector of within-cohort percentiles.
#' @param synergy Synergy strength in `[0, 1]`.
#' @param weights Optional named numeric potency weights aligned with `pct_vec`.
#' @return Scalar QTBI score.
#' @export
qtbi_from_vector <- function(pct_vec, synergy = 0.6, weights = NULL) {
  qtbi_from_state(build_statevector(pct_vec, synergy), weights = weights)
}

#' Gate schedule for circuit diagrams
#'
#' @param n_exposures Number of exposures (qubits).
#' @param n_metals Deprecated alias for `n_exposures`.
#' @return List with gate schedule metadata.
#' @export
circuit_gate_schedule <- function(n_exposures = 4L, n_metals = NULL) {
  if (!is.null(n_metals)) {
    n_exposures <- n_metals
  }
  list(
    n_exposures = n_exposures,
    n_metals = n_exposures,
    edges = .synergy_edges(n_exposures),
    triples = .synergy_triples(n_exposures)
  )
}
