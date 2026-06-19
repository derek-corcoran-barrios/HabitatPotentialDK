# Draft status

This scaffold is a methodological first draft. Before running:

1. Copy `Data/habitat_lookup_template.csv` to `Data/habitat_lookup.csv`.
2. Fill the source raster values.
3. Complete `Data/predictor_manifest.csv`.
4. Add predictor rasters under `Data/Predictors/`.
5. Initialize `renv`.
6. Render `README.Rmd` first with both run parameters set to `FALSE`.
7. Run preparation, inspect diagnostics, then run models.

The default model level is four abiotic classes. Change `cfg$model_level` to
`"habitat"` only when fitting eight independent models is scientifically justified.
