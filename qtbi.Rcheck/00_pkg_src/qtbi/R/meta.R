#' Retrieve QTBI metadata stored on a processed data frame
#'
#' @param data A `qtbi_data` object from [estimate_qtbi()].
#' @return List with chemicals, synergy strength, and percentile column names.
#' @export
qtbi_meta <- function(data) {
  if (!inherits(data, "qtbi_data")) {
    stop("`data` must be created with `estimate_qtbi()`.", call. = FALSE)
  }
  meta <- attr(data, "qtbi")
  if (is.null(meta)) {
    stop("`data` is missing QTBI metadata.", call. = FALSE)
  }
  meta
}

#' Test for a qtbi_data object
#'
#' @param x Object to test.
#' @return `TRUE` if `x` inherits from `"qtbi_data"`.
#' @export
is_qtbi_data <- function(x) {
  inherits(x, "qtbi_data")
}
