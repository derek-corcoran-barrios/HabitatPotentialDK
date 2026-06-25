# scripts/setup_environment.R

required_packages <- c(
  "terra", "sf", "dplyr", "purrr", "readr", "tibble", "tidyr", "ggplot2",
  "here", "fs", "blockCV", "ENMeval", "maxnet",
  "rangeModelMetadata", "knitr", "rmarkdown", "sessioninfo", 
  "tidyterra", "archive"
)

# This script must be run from the repository root:
# Rscript scripts/setup_environment.R
project_dir <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

lockfile_path <- file.path(project_dir, "renv.lock")

if (!file.exists(lockfile_path)) {
  stop(
    "Could not find renv.lock. Run this script from the repository root.",
    call. = FALSE
  )
}

# Usually renv is bootstrapped automatically by .Rprofile and
# renv/activate.R. This is only a fallback.
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages(
    "renv",
    repos = "https://cloud.r-project.org"
  )
}

lockfile <- renv::lockfile_read(lockfile_path)

current_r_minor <- paste(
  R.version$major,
  strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1],
  sep = "."
)

lockfile_r <- lockfile$R$Version

lockfile_r_minor <- paste(
  strsplit(lockfile_r, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

if (!identical(current_r_minor, lockfile_r_minor)) {
  warning(
    sprintf(
      paste0(
        "R-version mismatch: this computer uses R %s, ",
        "but renv.lock was generated with R %s. ",
        "Package restoration will be attempted, but this is not an ",
        "exact reproduction of the original environment."
      ),
      as.character(getRversion()),
      lockfile_r
    ),
    call. = FALSE
  )
}

not_recorded <- setdiff(
  required_packages,
  names(lockfile$Packages)
)

if (length(not_recorded) > 0L) {
  stop(
    "These required packages are not recorded in renv.lock: ",
    paste(not_recorded, collapse = ", "),
    call. = FALSE
  )
}

# Sequential installation is safer on shared or network-mounted filesystems.
options(
  renv.config.install.jobs = 1L,
  renv.config.install.verbose = TRUE
)

message("Restoring the existing renv environment...")

tryCatch(
  renv::restore(
    project = project_dir,
    lockfile = lockfile_path,
    packages = required_packages,
    prompt = FALSE,
    transactional = FALSE
  ),
  error = function(error) {
    warning(
      "The first restoration attempt was incomplete: ",
      conditionMessage(error),
      call. = FALSE
    )
  }
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

# Retry packages that are still unavailable.
if (length(missing_packages) > 0L) {
  message(
    "Retrying: ",
    paste(missing_packages, collapse = ", ")
  )
  
  tryCatch(
    renv::restore(
      project = project_dir,
      lockfile = lockfile_path,
      packages = missing_packages,
      rebuild = missing_packages,
      prompt = FALSE,
      transactional = FALSE
    ),
    error = function(error) {
      warning(
        "The retry was incomplete: ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
}

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0L) {
  stop(
    paste0(
      "Environment setup failed. These packages are still unavailable: ",
      paste(missing_packages, collapse = ", "),
      "\n\nPossible causes:",
      "\n- incompatibility with R ", as.character(getRversion()), ",",
      "\n- a missing server system library,",
      "\n- insufficient permissions, or",
      "\n- a network-filesystem installation problem."
    ),
    call. = FALSE
  )
}

message(
  "Environment setup completed successfully under R ",
  as.character(getRversion()),
  "."
)

renv::status(project = project_dir)
# scripts/setup_environment.R

required_packages <- c(
  "terra", "sf", "dplyr", "purrr", "readr", "tibble", "tidyr", "ggplot2",
  "here", "fs", "blockCV", "ENMeval", "maxnet",
  "rangeModelMetadata", "knitr", "rmarkdown", "sessioninfo"
)

# This script must be run from the repository root:
# Rscript scripts/setup_environment.R
project_dir <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

lockfile_path <- file.path(project_dir, "renv.lock")

if (!file.exists(lockfile_path)) {
  stop(
    "Could not find renv.lock. Run this script from the repository root.",
    call. = FALSE
  )
}

# Usually renv is bootstrapped automatically by .Rprofile and
# renv/activate.R. This is only a fallback.
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages(
    "renv",
    repos = "https://cloud.r-project.org"
  )
}

lockfile <- renv::lockfile_read(lockfile_path)

current_r_minor <- paste(
  R.version$major,
  strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1],
  sep = "."
)

lockfile_r <- lockfile$R$Version

lockfile_r_minor <- paste(
  strsplit(lockfile_r, ".", fixed = TRUE)[[1]][1:2],
  collapse = "."
)

if (!identical(current_r_minor, lockfile_r_minor)) {
  warning(
    sprintf(
      paste0(
        "R-version mismatch: this computer uses R %s, ",
        "but renv.lock was generated with R %s. ",
        "Package restoration will be attempted, but this is not an ",
        "exact reproduction of the original environment."
      ),
      as.character(getRversion()),
      lockfile_r
    ),
    call. = FALSE
  )
}

not_recorded <- setdiff(
  required_packages,
  names(lockfile$Packages)
)

if (length(not_recorded) > 0L) {
  stop(
    "These required packages are not recorded in renv.lock: ",
    paste(not_recorded, collapse = ", "),
    call. = FALSE
  )
}

# Sequential installation is safer on shared or network-mounted filesystems.
options(
  renv.config.install.jobs = 1L,
  renv.config.install.verbose = TRUE
)

message("Restoring the existing renv environment...")

tryCatch(
  renv::restore(
    project = project_dir,
    lockfile = lockfile_path,
    packages = required_packages,
    prompt = FALSE,
    transactional = FALSE
  ),
  error = function(error) {
    warning(
      "The first restoration attempt was incomplete: ",
      conditionMessage(error),
      call. = FALSE
    )
  }
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

# Retry packages that are still unavailable.
if (length(missing_packages) > 0L) {
  message(
    "Retrying: ",
    paste(missing_packages, collapse = ", ")
  )
  
  tryCatch(
    renv::restore(
      project = project_dir,
      lockfile = lockfile_path,
      packages = missing_packages,
      rebuild = missing_packages,
      prompt = FALSE,
      transactional = FALSE
    ),
    error = function(error) {
      warning(
        "The retry was incomplete: ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
}

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0L) {
  stop(
    paste0(
      "Environment setup failed. These packages are still unavailable: ",
      paste(missing_packages, collapse = ", "),
      "\n\nPossible causes:",
      "\n- incompatibility with R ", as.character(getRversion()), ",",
      "\n- a missing server system library,",
      "\n- insufficient permissions, or",
      "\n- a network-filesystem installation problem."
    ),
    call. = FALSE
  )
}

message(
  "Environment setup completed successfully under R ",
  as.character(getRversion()),
  "."
)

renv::status(project = project_dir)


####


required_packages <- c(
  "terra", "sf", "dplyr", "purrr", "readr", "tibble", "tidyr",
  "ggplot2", "here", "fs", "blockCV", "ENMeval", "maxnet",
  "rangeModelMetadata", "knitr", "rmarkdown", "sessioninfo",
  "tidyterra", "archive", "Rchelsa"
)

# This script must be run from the repository root:
# Rscript scripts/setup_environment.R

project_dir <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

# -------------------------------------------------------------------------
# 1. Install CRAN packages
# -------------------------------------------------------------------------

cran_packages <- setdiff(
  required_packages,
  "Rchelsa"
)

missing_cran_packages <- cran_packages[
  !vapply(
    cran_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_cran_packages) > 0) {
  renv::install(
    packages = missing_cran_packages,
    prompt = FALSE
  )
}

# -------------------------------------------------------------------------
# 2. Install Rchelsa from its Git repository
# -------------------------------------------------------------------------

if (!requireNamespace("Rchelsa", quietly = TRUE)) {
  renv::install(
    "Rchelsa=git::https://gitlabext.wsl.ch/karger/rchelsa.git",
    prompt = FALSE
  )
}

# -------------------------------------------------------------------------
# 3. Confirm key packages
# -------------------------------------------------------------------------

stopifnot(
  requireNamespace("cpp11", quietly = TRUE),
  requireNamespace("progress", quietly = TRUE),
  requireNamespace("RcppEigen", quietly = TRUE),
  requireNamespace("terra", quietly = TRUE),
  requireNamespace("glmnet", quietly = TRUE),
  requireNamespace("maxnet", quietly = TRUE),
  requireNamespace("archive", quietly = TRUE),
  requireNamespace("Rchelsa", quietly = TRUE)
)

# -------------------------------------------------------------------------
# 4. Rewrite the complete lockfile
# -------------------------------------------------------------------------

renv::snapshot(
  packages = required_packages,
  prompt = FALSE,
  force = TRUE
)

# -------------------------------------------------------------------------
# 5. Validate
# -------------------------------------------------------------------------

renv::status()

