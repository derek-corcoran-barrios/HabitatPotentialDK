# scripts/download_layers.R
# Public predictor acquisition for HabitatPotentialDK.
# Source this file from the project root, then call the functions at the end.

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

assert_command <- function(command) {
  if (!nzchar(Sys.which(command))) {
    stop("Required command-line program not found: ", command, call. = FALSE)
  }
  invisible(TRUE)
}

file_md5 <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  unname(tools::md5sum(path))
}

write_manifest <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

# -----------------------------------------------------------------------------
# EcoDes-DK15
# -----------------------------------------------------------------------------

ecodes_manifest <- data.frame(
  variable = c("Elevation", "Slope", "SolarRadiation", "TWI", "TopographicOpenness"),
  filename = c(
    "dtm_10m.tar.bz2",
    "slope.tar.bz2",
    "solar_radiation.tar.bz2",
    "twi.tar.bz2",
    "openness_mean.tar.bz2"
  ),
  md5 = c(
    "f8e599eaabc62c1ac44ff9290ab47746",
    "1f55790a242cc069a6c0f9f8057d31ec",
    "ba3df991fb9bf643c22e31cb1dab7214",
    "dd552e3fe8688d4a274ff5de65b4ea26",
    "2e0e890accadee699240955a56a13691"
  ),
  conversion_divisor = c(100, 10, 1, 1000, 1),
  core = c(TRUE, TRUE, TRUE, TRUE, FALSE),
  stringsAsFactors = FALSE
)

download_resumable <- function(url, destination, expected_md5 = NULL, retries = 10L) {
  assert_command("curl")
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  
  if (file.exists(destination) && !is.null(expected_md5)) {
    if (identical(tolower(file_md5(destination)), tolower(expected_md5))) {
      message("Already downloaded and verified: ", basename(destination))
      return(invisible(destination))
    }
  }
  
  if (file.exists(destination)) {
    message(
      "Resuming partial download: ", basename(destination),
      " (", format(file.size(destination), big.mark = ","), " bytes present)"
    )
  } else {
    message("Downloading: ", basename(destination))
  }
  
  status <- system2(
    "curl",
    args = c(
      "-L", "--fail",
      "--retry", as.character(retries),
      "--retry-all-errors", "--retry-delay", "10",
      "--connect-timeout", "60",
      "-C", "-",
      "--output", shQuote(destination),
      shQuote(url)
    )
  )
  
  if (!identical(status, 0L)) {
    stop(
      "Download did not complete for ", basename(destination), ".\n",
      "The partial file was retained; rerun the same call to resume.",
      call. = FALSE
    )
  }
  
  if (!is.null(expected_md5)) {
    observed_md5 <- file_md5(destination)
    if (!identical(tolower(observed_md5), tolower(expected_md5))) {
      stop(
        "Checksum failed for ", basename(destination), ".\n",
        "Expected: ", expected_md5, "\nObserved: ", observed_md5,
        call. = FALSE
      )
    }
  }
  
  message("Downloaded and verified: ", basename(destination))
  invisible(destination)
}

download_ecodes <- function(
    destination = here::here("Data_raw", "Open", "EcoDes"),
    include_optional = TRUE,
    extract = FALSE,
    retries = 10L) {
  
  manifest <- ecodes_manifest
  if (!include_optional) manifest <- manifest[manifest$core, , drop = FALSE]
  
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  base_url <- "https://zenodo.org/records/5752926/files/"
  paths <- character(nrow(manifest))
  
  for (i in seq_len(nrow(manifest))) {
    paths[i] <- download_resumable(
      url = paste0(base_url, manifest$filename[i], "?download=1"),
      destination = file.path(destination, manifest$filename[i]),
      expected_md5 = manifest$md5[i],
      retries = retries
    )
  }
  
  manifest$archive_path <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  manifest$downloaded_bytes <- file.size(paths)
  manifest$observed_md5 <- vapply(paths, file_md5, character(1))
  manifest$verified <- tolower(manifest$observed_md5) == tolower(manifest$md5)
  
  write_manifest(manifest, file.path(destination, "ecodes_download_manifest.csv"))
  
  if (extract) {
    extract_ecodes(paths, file.path(destination, "extracted"))
  }
  
  invisible(paths)
}

extract_ecodes <- function(
    archives,
    destination = here::here("Data_raw", "Open", "EcoDes", "extracted"),
    overwrite = FALSE) {
  
  if (!requireNamespace("archive", quietly = TRUE)) {
    stop("Install package 'archive' before extracting EcoDes files.", call. = FALSE)
  }
  
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  output_dirs <- character(length(archives))
  
  for (i in seq_along(archives)) {
    layer_name <- sub("\\.tar\\.bz2$", "", basename(archives[i]))
    output_dir <- file.path(destination, layer_name)
    marker <- file.path(output_dir, ".extraction_complete")
    output_dirs[i] <- output_dir
    
    if (file.exists(marker) && !overwrite) {
      message("Already extracted: ", basename(archives[i]))
      next
    }
    
    if (dir.exists(output_dir) && overwrite) {
      unlink(output_dir, recursive = TRUE, force = TRUE)
    }
    
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    message("Extracting: ", basename(archives[i]))
    archive::archive_extract(archives[i], dir = output_dir)
    writeLines(format(Sys.time(), tz = "UTC"), marker)
  }
  
  invisible(output_dirs)
}

# -----------------------------------------------------------------------------
# CHELSA climate
# -----------------------------------------------------------------------------

denmark_extent_lonlat <- function(template_path) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Install package 'terra'.", call. = FALSE)
  }
  if (!file.exists(template_path)) stop("Template raster not found: ", template_path)
  
  template <- terra::rast(template_path)
  boundary <- terra::as.polygons(terra::ext(template), crs = terra::crs(template))
  boundary <- terra::project(boundary, "EPSG:4326")
  e <- terra::ext(boundary)
  c(terra::xmin(e), terra::xmax(e), terra::ymin(e), terra::ymax(e))
}

write_cog <- function(x, filename, overwrite = FALSE) {
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  terra::writeRaster(
    x, filename,
    overwrite = overwrite,
    filetype = "COG",
    datatype = "FLT4S",
    gdal = c("COMPRESS=DEFLATE", "LEVEL=9", "BLOCKSIZE=512", "BIGTIFF=IF_SAFER"),
    NAflag = -9999
  )
  invisible(filename)
}

download_chelsa_climate <- function(
    template_path,
    destination = here::here("Data_raw", "Open", "CHELSA"),
    startdate = as.Date("1981-01-01"),
    enddate = as.Date("2010-12-01"),
    summer_months = 5:9,
    overwrite = FALSE) {
  
  required <- c("terra", "Rchelsa")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Install: ", paste(missing, collapse = ", "), call. = FALSE)
  
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  extent <- denmark_extent_lonlat(template_path)
  dates <- seq(startdate, enddate, by = "month")
  years <- length(unique(format(dates, "%Y")))
  
  if (length(dates) != years * 12L) {
    stop("CHELSA period must contain complete calendar years.", call. = FALSE)
  }
  
  output <- c(
    MeanAnnualTemperature = file.path(destination, "CHELSA_1981-2010_mean_temperature_C.tif"),
    AnnualPrecipitation = file.path(destination, "CHELSA_1981-2010_annual_precipitation.tif"),
    AnnualPET = file.path(destination, "CHELSA_1981-2010_annual_pet.tif"),
    SummerWaterBalance = file.path(destination, "CHELSA_1981-2010_May-Sep_water_balance.tif")
  )
  
  if (all(file.exists(output)) && !overwrite) {
    message("All derived CHELSA layers already exist.")
    return(invisible(output))
  }
  
  message("Reading CHELSA monthly temperature...")
  tas <- Rchelsa::getChelsa(
    "tas", extent = extent, startdate = startdate, enddate = enddate,
    dataset = "chelsa-monthly"
  )
  stopifnot(terra::nlyr(tas) == length(dates))
  mean_temp <- terra::mean(tas, na.rm = TRUE) - 273.15
  names(mean_temp) <- "MeanAnnualTemperature_C"
  write_cog(mean_temp, output[["MeanAnnualTemperature"]], overwrite)
  rm(tas, mean_temp); invisible(gc())
  
  message("Reading CHELSA monthly precipitation...")
  pr <- Rchelsa::getChelsa(
    "pr", extent = extent, startdate = startdate, enddate = enddate,
    dataset = "chelsa-monthly"
  )
  
  message("Reading CHELSA monthly potential evapotranspiration...")
  pet <- Rchelsa::getChelsa(
    "pet", extent = extent, startdate = startdate, enddate = enddate,
    dataset = "chelsa-monthly"
  )
  
  stopifnot(terra::nlyr(pr) == length(dates), terra::nlyr(pet) == length(dates))
  summer <- as.integer(format(dates, "%m")) %in% summer_months
  
  annual_pr <- terra::sum(pr, na.rm = TRUE) / years
  annual_pet <- terra::sum(pet, na.rm = TRUE) / years
  summer_balance <- (
    terra::sum(pr[[summer]], na.rm = TRUE) -
      terra::sum(pet[[summer]], na.rm = TRUE)
  ) / years
  
  names(annual_pr) <- "AnnualPrecipitation_kg_m2"
  names(annual_pet) <- "AnnualPET_kg_m2"
  names(summer_balance) <- "SummerWaterBalance_kg_m2"
  
  write_cog(annual_pr, output[["AnnualPrecipitation"]], overwrite)
  write_cog(annual_pet, output[["AnnualPET"]], overwrite)
  write_cog(summer_balance, output[["SummerWaterBalance"]], overwrite)
  
  manifest <- data.frame(
    variable = names(output),
    file = normalizePath(output, winslash = "/", mustWork = TRUE),
    source = "CHELSA-monthly",
    version = "2.1",
    period_start = as.character(startdate),
    period_end = as.character(enddate),
    native_scale = "kilometre-scale",
    stringsAsFactors = FALSE
  )
  write_manifest(manifest, file.path(destination, "chelsa_climate_manifest.csv"))
  
  invisible(output)
}

# -----------------------------------------------------------------------------
# Suggested calls from the project root
# -----------------------------------------------------------------------------

# ecodes_archives <- download_ecodes(include_optional = TRUE, extract = FALSE)
# ecodes_dirs <- extract_ecodes(ecodes_archives)
#
# chelsa_layers <- download_chelsa_climate(
#   template_path = here::here("Data", "basemap_reclass_SN_ModelClass.tif")
# )
