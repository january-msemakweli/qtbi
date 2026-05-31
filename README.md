# qtbi

[![R-CMD-check](https://github.com/january-msemakweli/qtbi/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/january-msemakweli/qtbi/actions/workflows/R-CMD-check.yaml)

**Quantum Toxic Burden Index (QTBI)** — encode correlated environmental exposures into a single, reproducible mixture burden score using a fixed quantum-inspired circuit.

QTBI is designed for **environmental mixture epidemiology**: you specify the exposure panel and (optionally) external potency benchmarks **before** outcome modeling. The encoder does not reweight components from the disease outcome.

## Why use QTBI?

| Step | What QTBI does |
|------|----------------|
| 1. Normalize | Each exposure becomes a within-cohort percentile on `[0, 1]` |
| 2. Encode | Percentiles pass through a fixed entanglement circuit controlled by synergy `s` |
| 3. Read out | Marginal toxic probabilities sum to one scalar QTBI on `[0, n]` |
| 4. Analyze | Use the scalar in standard regression (logistic, linear, etc.) |

Optional **potency-weighted readout** applies external oral reference doses at the final step only, with automatic rescaling so weighted QTBI stays on the same `[0, n]` scale as the unweighted index.

## Installation

```r
install.packages("qtbi")  # after CRAN acceptance
# or:
# install.packages("remotes")
remotes::install_github("january-msemakweli/qtbi")
```

From a local clone of this repository:

```r
install.packages(".", repos = NULL, type = "source")
```

Requirements: **R (>= 4.1.0)**. No compiled code. No non-base runtime dependencies.

## Quick start: four-metal mixture

```r
library(qtbi)

# Example exposure data (complete cases only)
df <- data.frame(
  LBXBPB = c(0.8, 1.2, 2.1, 0.9),   # blood lead
  URXIAS = c(3.5, 8.2, 4.1, 12.0),  # urinary inorganic As + metabolites
  LBXBCD = c(0.2, 0.4, 0.3, 0.6),   # blood cadmium
  LBXTHG = c(0.5, 1.1, 2.0, 0.7)    # blood mercury
)

# Unweighted QTBI (equal readout weights)
processed <- estimate_qtbi(
  df,
  chemicals = c("LBXBPB", "URXIAS", "LBXBCD", "LBXTHG"),
  exposure_names = c("Pb", "As", "Cd", "Hg"),
  synergy_strength = 0.6
)

processed$qtbi
diagnose_qtbi(processed)
```

## Potency-weighted QTBI

Supply oral reference doses in **mg/kg/day** (one per exposure). The package derives potency ratios, rescales weights to sum to `n`, and applies them at readout only.

```r
ref <- c(
  Pb = 6.3e-4,   # external benchmark (mg/kg/day)
  As = 6.0e-5,
  Cd = 5.0e-4,
  Hg = 1.0e-4
)

weighted <- estimate_qtbi(
  df,
  chemicals = c("LBXBPB", "URXIAS", "LBXBCD", "LBXTHG"),
  exposure_names = c("Pb", "As", "Cd", "Hg"),
  synergy_strength = 0.6,
  reference_doses = ref,
  reference_index = "Pb"
)

qtbi_meta(weighted)$potency_weights
```

Inspect weights explicitly:

```r
raw <- potency_weights_from_reference_doses(ref, c("Pb", "As", "Cd", "Hg"), "Pb")
normalize_potency_weights(raw)
```

**Important:** align each biomarker with the chemical form used in its benchmark, and review absolute cohort distributions before applying potency weights. A high regulatory weight on a background-level exposure can dominate the index.

## Recommended workflow for mixture modeling

```r
library(qtbi)

# 1. Prepare a complete-case analytic frame (no missing exposures)
# 2. Choose panel members (known/suspected toxicants, same direction)
# 3. Encode unweighted and (optionally) potency-weighted QTBI
processed_unw <- estimate_qtbi(
  df,
  chemicals = exposure_cols,
  exposure_names = metal_names,
  synergy_strength = 0.6
)

processed_wgt <- estimate_qtbi(
  df,
  chemicals = exposure_cols,
  exposure_names = metal_names,
  synergy_strength = 0.6,
  reference_doses = reference_doses,
  reference_index = "Pb"
)

# 4. Encoder diagnostics (exposure-only; no outcome)
diagnose_qtbi(processed_unw)
synergy_sensitivity(processed_unw, synergy_grid = seq(0, 1, by = 0.1))

# 5. Outcome modeling with standard tools
# glm(ckd ~ qtbi + covariates, data = processed_unw, family = binomial())
```

### Design checklist

1. **Panel selection** — include only exposures assumed to increase burden in the same direction.
2. **Biomarker–benchmark alignment** — e.g. speciated inorganic arsenic for an inorganic arsenic RfD, not urinary total arsenic.
3. **Distribution review** — inspect medians/IQRs; percentiles alone can rank low absolute levels highly.
4. **Synergy setting** — use `diagnose_qtbi()` / `synergy_sensitivity()` over `s ∈ [0, 1]` without the outcome.
5. **Compare readouts** — report unweighted and potency-weighted QTBI side by side when weights are used.

## Main functions

| Function | Purpose |
|----------|---------|
| `estimate_qtbi()` | Percentile encoding + index computation |
| `diagnose_qtbi()` | Synergy sensitivity and monotonicity checks |
| `potency_weights_from_reference_doses()` | Raw potency ratios from oral benchmarks |
| `normalize_potency_weights()` | Rescale weights to the unweighted `[0, n]` scale |
| `qtbi_meta()` | Chemicals, synergy, weights, column names |
| `qtbi_help()` | Interactive help index |

Advanced exports include `build_statevector()`, `qtbi_from_pcts()`, and `synergy_diagnostics()`.

## Repository layout

```
qtbi/
├── R/              # Package source
├── man/            # Documentation
├── tests/          # testthat suite
├── DESCRIPTION
├── NAMESPACE
├── NEWS.md
├── LICENSE
└── README.md
```

See the `illustration/` folder in the GitHub repository for a minimal NHANES metal mixture example.

## Development

```bash
R CMD build .
R CMD check qtbi_0.1.2.tar.gz --as-cran --no-manual
```

Run tests in R:

```r
testthat::test_local()
```

## Citation

If you use this package, please cite the methods specification and this software:

```
Msemakweli JG (2026). The Quantum Toxic Burden Index: Mathematical Specification.
Zenodo. https://doi.org/10.5281/zenodo.20476574

Msemakweli JG (2026). qtbi: Quantum Toxic Burden Index. R package version 0.1.2.
https://github.com/january-msemakweli/qtbi
```

## License

MIT © January G. Msemakweli
