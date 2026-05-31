# Internal statevector simulator for the QTBI entanglement encoder.

.theta <- function(p) {
  2 * asin(sqrt(pmax(0, pmin(1, p))))
}

.apply_1q <- function(state, gate, q, n) {
  dim <- 2L^n
  out <- state
  stride <- 2L^q
  pairs <- dim / (2L * stride)
  for (i in seq_len(pairs) - 1L) {
    for (j in seq_len(stride) - 1L) {
      idx0 <- i * 2L * stride + j + 1L
      idx1 <- idx0 + stride
      a <- state[idx0]
      b <- state[idx1]
      out[idx0] <- gate[1, 1] * a + gate[1, 2] * b
      out[idx1] <- gate[2, 1] * a + gate[2, 2] * b
    }
  }
  out
}

.ry_gate <- function(theta) {
  c <- cos(theta / 2)
  s <- sin(theta / 2)
  matrix(c(c, -s, s, c), nrow = 2)
}

.apply_ry <- function(state, theta, q, n) {
  .apply_1q(state, .ry_gate(theta), q, n)
}

.apply_cry <- function(state, theta, control, target, n) {
  dim <- 2L^n
  out <- state
  cstride <- 2L^control
  tstride <- 2L^target
  g <- .ry_gate(theta)
  pairs <- dim / (2L * tstride)
  for (i in seq_len(pairs) - 1L) {
    for (j in seq_len(tstride) - 1L) {
      idx0 <- i * 2L * tstride + j + 1L
      idx1 <- idx0 + tstride
      if (bitwAnd(as.integer(idx0 - 1L), cstride) == 0L) next
      a <- state[idx0]
      b <- state[idx1]
      out[idx0] <- g[1, 1] * a + g[1, 2] * b
      out[idx1] <- g[2, 1] * a + g[2, 2] * b
    }
  }
  out
}

.apply_mcx <- function(state, controls, target, n) {
  dim <- 2L^n
  out <- state
  tstride <- 2L^target
  for (i in seq_len(dim)) {
    idx <- as.integer(i - 1L)
    if (bitwAnd(idx, tstride) != 0L) next
    if (!all(vapply(controls, function(q) bitwAnd(idx, 2L^q) != 0L, logical(1)))) next
    j <- i + tstride
    tmp <- out[[i]]
    out[[i]] <- out[[j]]
    out[[j]] <- tmp
  }
  out
}

.apply_ccry <- function(state, theta, controls, target, n) {
  if (length(controls) == 1L) {
    return(.apply_cry(state, theta, controls[[1]], target, n))
  }
  state <- .apply_ry(state, theta / 2, target, n)
  state <- .apply_mcx(state, controls, target, n)
  state <- .apply_ry(state, -theta / 2, target, n)
  state <- .apply_mcx(state, controls, target, n)
  state
}

.bit <- function(idx, q) {
  bitwAnd(as.integer(idx), 2L^q) != 0L
}

.raw_synergy_edges <- function(n) {
  edges <- list()
  if (n >= 2) {
    for (t in seq(1, n - 1)) edges[[length(edges) + 1L]] <- c(0, t, 1.0)
  }
  if (n >= 4) {
    edges[[length(edges) + 1L]] <- c(2, 3, 0.7)
    edges[[length(edges) + 1L]] <- c(1, 2, 0.5)
    edges[[length(edges) + 1L]] <- c(1, 3, 0.5)
  }
  do.call(rbind, edges)
}

.synergy_edges <- function(n) {
  raw <- .raw_synergy_edges(n)
  if (is.null(raw)) return(matrix(numeric(0), ncol = 3))
  in_w <- stats::setNames(rep(0, n), as.character(seq(0, n - 1)))
  for (i in seq_len(nrow(raw))) {
    in_w[[as.character(raw[i, 2])]] <- in_w[[as.character(raw[i, 2])]] + raw[i, 3]
  }
  cbind(raw[, 1:2], raw[, 3] / pmax(1, in_w[as.character(raw[, 2])]))
}

.synergy_triples <- function(n) {
  if (n < 4) return(list())
  list(
    list(ctrls = c(0, 2), tgt = 3, w = 0.20),
    list(ctrls = c(0, 1, 2), tgt = 3, w = 0.10)
  )
}
