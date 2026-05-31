#' Package help index for qtbi
#'
#' Prints a topic index for the main **qtbi** functions and optionally opens
#' documentation for a specific topic. Use this when you want a guided entry
#' point to the package; standard R help remains available via `?function_name`
#' and `help(package = "qtbi")`.
#'
#' @param topic Optional character string naming a function or topic to open.
#'   If omitted, a summary index is printed.
#'
#' @return Invisibly returns `NULL`. When `topic` is supplied, the corresponding
#'   help page is opened as a side effect.
#' @export
#'
#' @examples
#' qtbi_help()
#' \dontrun{
#' qtbi_help("estimate_qtbi")
#' help(package = "qtbi")
#' }
qtbi_help <- function(topic = NULL) {
  index <- c(
    estimate_qtbi = "Encode exposures and append QTBI scores to a data frame",
    diagnose_qtbi = "Synergy sensitivity and monotonicity diagnostics",
    qtbi_meta = "Retrieve chemicals, synergy, and column metadata",
    potency_weights_from_reference_doses = "Derive potency weights from reference doses",
    normalize_potency_weights = "Rescale potency weights to the unweighted QTBI scale",
    exposure_percentile = "Convert one exposure vector to cohort percentiles",
    percentile_matrix = "Build a percentile matrix from exposure columns",
    build_statevector = "Construct the entanglement statevector",
    qtbi_from_pcts = "Compute QTBI from a percentile matrix",
    synergy_diagnostics = "Full encoder diagnostic tables"
  )

  if (is.null(topic)) {
    cat("qtbi - Quantum Toxic Burden Index\n\n")
    cat("Typical workflow:\n")
    cat("  1. estimate_qtbi()  encode exposures and compute QTBI\n")
    cat("  2. diagnose_qtbi()  review encoder diagnostics\n\n")
    cat("Function index:\n")
    width <- max(nchar(names(index)), 0L)
    for (nm in names(index)) {
      cat(sprintf("  %-*s  %s\n", width, nm, index[[nm]]))
    }
    cat("\nOpen help for one function:\n")
    cat('  qtbi_help("estimate_qtbi")   or   ?estimate_qtbi\n')
    cat("Browse all documentation:\n")
    cat('  help(package = "qtbi")\n')
    return(invisible(NULL))
  }

  topic <- topic[[1L]]
  if (!topic %in% names(index)) {
    stop(
      "Unknown topic '", topic, "'. Run qtbi_help() for available topics.",
      call. = FALSE
    )
  }

  utils::help(topic, package = "qtbi")
  invisible(NULL)
}
