test_that("estimate_qtbi adds qtbi column and metadata", {
  df <- data.frame(
    Pb = c(1, 2, 3, 4),
    As = c(4, 3, 2, 1),
    Cd = c(2, 2, 3, 3),
    Hg = c(1, 3, 2, 4),
    ckd = c(0, 0, 1, 1)
  )
  out <- estimate_qtbi(
    df,
    chemicals = c("Pb", "As", "Cd", "Hg"),
    synergy_strength = 0.6,
    exposure_names = c("Pb", "As", "Cd", "Hg")
  )
  expect_s3_class(out, "qtbi_data")
  expect_true("qtbi" %in% names(out))
  expect_equal(qtbi_meta(out)$synergy_strength, 0.6)
  expect_true(all(out$qtbi >= 0 & out$qtbi <= 4))
})

test_that("qtbi_help prints index without error", {
  expect_invisible(qtbi_help())
})

test_that("qtbi_help rejects unknown topics", {
  expect_error(qtbi_help("not_a_function"), "Unknown topic")
})

test_that("diagnose_qtbi returns monotonicity summary", {
  df <- data.frame(
    Pb = rep(1:10, each = 2),
    As = rep(10:1, each = 2),
    Cd = rep(5, 20),
    Hg = seq(1, 10, length.out = 20)
  )
  processed <- estimate_qtbi(df, chemicals = c("Pb", "As", "Cd", "Hg"))
  diag <- diagnose_qtbi(processed, verbose = FALSE)
  expect_s3_class(diag, "qtbi_diagnosis")
  expect_true(nrow(diag$monotonicity) == 1)
})

test_that("reference_doses derive rescaled potency weights at readout", {
  df <- data.frame(
    Pb = c(1, 2, 3, 4),
    As = c(4, 3, 2, 1),
    Cd = c(2, 2, 3, 3),
    Hg = c(1, 3, 2, 4)
  )
  ref <- c(Pb = 6.3e-4, As = 6.0e-5, Cd = 5.0e-4, Hg = 1.0e-4)
  out <- estimate_qtbi(
    df,
    chemicals = c("Pb", "As", "Cd", "Hg"),
    exposure_names = c("Pb", "As", "Cd", "Hg"),
    reference_doses = ref,
    reference_index = "Pb"
  )
  meta <- qtbi_meta(out)
  expect_true(meta$weighted)
  expect_equal(meta$reference_index, "Pb")
  expect_equal(meta$potency_weights_raw[["Pb"]], 1)
  expect_true(meta$potency_weights_raw[["As"]] > meta$potency_weights_raw[["Pb"]])
  expect_equal(sum(meta$potency_weights), 4, tolerance = 1e-12)
  expect_true(all(out$qtbi >= 0 & out$qtbi <= 4))
  unw <- estimate_qtbi(df, chemicals = c("Pb", "As", "Cd", "Hg"))
  expect_false(identical(out$qtbi, unw$qtbi))
})

test_that("normalize_potency_weights rescales to panel size", {
  raw <- c(Pb = 1, As = 10.5, Cd = 1.26, Hg = 6.3)
  scaled <- normalize_potency_weights(raw)
  expect_equal(sum(scaled), 4, tolerance = 1e-12)
  expect_equal(scaled[["Pb"]], 4 * 1 / sum(raw), tolerance = 1e-12)
})

test_that("potency_weights_from_reference_doses validates input", {
  expect_error(
    potency_weights_from_reference_doses(c(1, 2), c("A", "B")),
    "named numeric vector"
  )
})
