## Test environments
* local R 4.5.3 (Windows 11, x86_64-w64-mingw32)
* GitHub Actions R-CMD-check (Windows, macOS, Ubuntu)
* win-builder incoming pre-test (2026-05-31)

## R CMD check results
0 errors | 0 warnings | 0 notes (expected after fixes below)

## Reverse dependencies
This is a new submission.

## Resubmission notes (0.1.2)

Resubmission addressing CRAN incoming feedback from 2026-05-30 and win-builder pre-test notes from 2026-05-31.

**2026-05-30 (Uwe Ligges):**
* Removed the acronym "QTBI" from the `Description` field.
* Added method DOI `<doi:10.5281/zenodo.20476574>` (Msemakweli JG, 2026, Zenodo).
* Removed invalid relative file URIs from `README.md`.

**2026-05-31 (win-builder pre-test):**
* Removed maintainer surname from `Description` to avoid aspell NOTE; author and year remain on the Zenodo record linked by the DOI. `URL` now also lists https://doi.org/10.5281/zenodo.20476574.
* Excluded `illustration/` from the CRAN tarball via `.Rbuildignore` (example script and data remain in the GitHub repository under `illustration/`).

There are no downstream dependencies on CRAN.
