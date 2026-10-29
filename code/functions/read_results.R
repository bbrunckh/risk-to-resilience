# Readers for the batch output tables (results/<project>/).

r2r_results_dir <- function(project) file.path("results", project)

# One table of a project as a tibble (hive-partitioned by country code).
read_table <- function(project, name) {
  arrow::open_dataset(file.path(r2r_results_dir(project), "tables", name)) |>
    dplyr::collect()
}

# Survey statistics of the descriptives project, one row per survey wave (the
# pooled "All" rows dropped), for the sample `sample`. A variable listed under
# two var_groups (for example welfare as outcome and hh) has identical rows:
# one is kept.
wave_stats <- function(sample = "all") {
  samp <- sample
  read_table("descriptives", "variable_stats") |>
    dplyr::filter(wave != "All", .data$sample == samp) |>
    dplyr::distinct(code, wave, variable, .keep_all = TRUE) |>
    dplyr::mutate(year = as.integer(year))
}

# weather_stats of the descriptives project with the reference period (months):
# one row per country, wave, variable and source ("survey" or "historical"),
# sample "all". Wave "All" is the pooled row.
weather_profiles <- function() {
  axes <- read_runs("descriptives") |>
    dplyr::select(axis_weather, wxvar_ids) |>
    tidyr::unnest(wxvar_ids) |>
    dplyr::distinct(wxvar_id = wxvar_ids, axis_weather) |>
    dplyr::mutate(ref_months = as.integer(stringr::str_extract(axis_weather, "\\d+(?=m$)")))
  read_table("descriptives", "weather_stats") |>
    dplyr::filter(sample == "all") |>
    dplyr::inner_join(axes, by = "wxvar_id")
}

# One row per run: run ids, the axis labels of the spec and the stage ids.
read_runs <- function(project) {
  arrow::read_parquet(file.path(r2r_results_dir(project), "runs.parquet"))
}

# Read failures.parquet and manifest.json before using any table of a project
# (AGENTS.md). Reports the failed stage ids with the run ids they affect.
check_batch <- function(project) {
  dir <- r2r_results_dir(project)
  n <- jsonlite::read_json(file.path(dir, "manifest.json"))$n_failures
  fail <- arrow::read_parquet(file.path(dir, "failures.parquet"))
  if (isTRUE(n > 0) || nrow(fail) > 0) {
    cli::cli_alert_warning("{project}: {n} batch failure{?s}")
    for (i in seq_len(nrow(fail))) {
      cli::cli_alert("{fail$stage[i]} {fail$id[i]} (runs {fail$run_ids[i]}): {fail$message[i]}")
    }
  } else {
    cli::cli_alert_success("{project}: no batch failures")
  }
  invisible(fail)
}
