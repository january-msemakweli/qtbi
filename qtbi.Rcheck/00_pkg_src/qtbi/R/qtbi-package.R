#' Quantum Toxic Burden Index
#'
#' @description
#' Compute the Quantum Toxic Burden Index (QTBI) from multi-exposure panels
#' using a fixed quantum-inspired entanglement encoder.
#'
#' @section Typical workflow:
#' * [estimate_qtbi()] adds percentile and QTBI columns to your data frame.
#' * Optional `reference_doses` enable potency-weighted readout at the index step.
#'   Weights are rescaled automatically so weighted QTBI stays on the same
#'   `[0, n]` scale as the unweighted index.
#' * [diagnose_qtbi()] summarizes synergy sensitivity and monotonicity.
#'
#' @keywords internal
"_PACKAGE"
