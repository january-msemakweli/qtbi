#' Convert exposures to within-cohort percentiles
#'
#' @param x Numeric exposure vector.
#' @return Numeric percentiles in `(0, 1]`.
#' @export
exposure_percentile <- function(x) {
  if (all(is.na(x))) return(x)
  r <- rank(x, ties.method = "average", na.last = "keep")
  r / sum(!is.na(x))
}

#' Build percentile matrix from a data frame
#'
#' @param data Data frame containing exposure columns.
#' @param chemicals Character vector of column names.
#' @return Numeric matrix with one percentile column per chemical.
#' @export
percentile_matrix <- function(data, chemicals) {
  .check_chemical_cols(data, chemicals)
  out <- vapply(chemicals, function(col) exposure_percentile(data[[col]]), numeric(nrow(data)))
  if (!is.matrix(out)) out <- matrix(out, ncol = 1L)
  colnames(out) <- chemicals
  out
}

.pct_col_name <- function(chemical) {
  paste0("pct_", make.names(chemical, unique = TRUE))
}

.check_chemical_cols <- function(data, chemicals) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (length(chemicals) < 1L) {
    stop("`chemicals` must name at least one exposure column.", call. = FALSE)
  }
  miss <- setdiff(chemicals, names(data))
  if (length(miss)) {
    stop(
      "Missing exposure columns in `data`: ", paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  if (anyNA(data[chemicals])) {
    stop(
      "Exposure columns contain missing values. Use complete cases before calling `estimate_qtbi()`.",
      call. = FALSE
    )
  }
  invisible(NULL)
}
