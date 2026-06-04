# qtbi 0.1.2

* Initial CRAN release.
* `estimate_qtbi()` encodes multi-exposure panels into a fixed Quantum Toxic
  Burden Index using within-cohort percentiles and a configurable synergy
  parameter.
* Optional potency-weighted readout via `reference_doses`, with automatic
  derivation and rescaling of weights through
  `potency_weights_from_reference_doses()` and `normalize_potency_weights()`.
* `diagnose_qtbi()` provides synergy sensitivity and monotonicity diagnostics.
* Classical statevector simulation only; no quantum hardware or heavy
  visualization dependencies.
