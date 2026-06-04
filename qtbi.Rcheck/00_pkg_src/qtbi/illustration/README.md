# NHANES QTBI illustration (minimal)

This folder contains a **minimal** script matching the NHANES CKD illustration in the QTBI manuscript: encode QTBI (unweighted and potency-weighted), then fit adjusted logistic regression models. It does **not** write CSV files, figures, or synergy diagnostic plots.

## Requirements

- R (>= 4.1.0)
- CRAN packages: **qtbi**, **readr**, **dplyr**

Install **qtbi**:

```r
install.packages("qtbi")  # after CRAN release
# or: remotes::install_github("january-msemakweli/qtbi")
```

## Bundled data

Analytic NHANES 2011–2018 data (`n = 6,977`, matching the manuscript cohort) are included at:

```
illustration/data/nhanes_qtbi.csv
```

| Column | Description |
|--------|-------------|
| `LBXBPB`, `URXIAS`, `LBXBCD`, `LBXTHG` | Exposure biomarkers |
| `ckd` | Binary CKD indicator |
| `RIDAGEYR`, `RIAGENDR`, `RIDRETH3` | Demographics for adjusted models |

`URXIAS` is speciated inorganic arsenic, not urinary total arsenic.

To use another CSV, pass `--data=/path/to/file.csv`.

## Run

From the repository root:

```bash
Rscript illustration/nhanes_ckd_illustration.R
```

Or from an R session:

```r
source("illustration/nhanes_ckd_illustration.R")
```

QTBI ranges and adjusted odds ratios are printed to the console only.
