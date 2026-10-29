# Decile decomposition of a policy effect in the 1-in-20 year (Fig 13, 17).
#
# 1-in-20 year (legacy/04c): the weather year whose total policy effect (delta
# total summed over deciles, median across climate-model members) is nearest the
# 95th percentile across years. Channel effects are on the log scale, shown as
# percent change in welfare: (exp(delta) - 1) x 100.

decomposition_channels <- c(
  delta_sp = "Social protection (direct)",
  delta_main_covar = "Main effect (covariate shift)",
  delta_res1 = "Resilience: repositioning",
  delta_res2 = "Resilience: interaction"
)
# Hex values of r2r_col$navy, $ssp3 and $policy (files are sourced alphabetically).
decomposition_colours <- c(
  "Social protection (direct)" = "#002244",
  "Main effect (covariate shift)" = "#0072B2",
  "Resilience: repositioning" = "#D55E00",
  "Resilience: interaction" = "#E8A06E"
)
decomposition_scenarios <- c(
  Historical = "Historical (1991-2020)",
  "SSP3-7.0 / 2040-2060" = "SSP3 2050 (2040-2060)"
)

# One row per scenario x decile x channel: the percent change in welfare in the
# 1-in-20 year of the scenario. NULL when the project has no such run.
decomposition_1in20 <- function(project, country, policy) {
  run <- sim_runs(project) |>
    dplyr::filter(code == country, axis_policy == policy, !is.na(policy_id))
  if (nrow(run) == 0L) {
    return(NULL)
  }
  dd <- read_table(project, "decomposition") |>
    dplyr::filter(policy_id == run$policy_id[1], source == "compact",
                  scenario %in% names(decomposition_scenarios),
                  channel %in% c("delta_total", names(decomposition_channels)),
                  grepl("^decile_", group)) |>
    dplyr::summarise(value = stats::median(value, na.rm = TRUE),
                     .by = c(scenario, group, sim_year, channel))
  year_1in20 <- dd |>
    dplyr::filter(channel == "delta_total") |>
    dplyr::summarise(total = sum(value), .by = c(scenario, sim_year)) |>
    dplyr::slice(which.min(abs(total - stats::quantile(total, 0.95))), .by = scenario) |>
    dplyr::select(scenario, sim_year)
  dd |>
    dplyr::inner_join(year_1in20, by = c("scenario", "sim_year")) |>
    dplyr::filter(channel %in% names(decomposition_channels)) |>
    dplyr::mutate(
      decile = as.integer(sub("decile_", "", group)),
      pct = (exp(value) - 1) * 100,
      channel = factor(decomposition_channels[channel], levels = decomposition_channels),
      scenario = factor(decomposition_scenarios[scenario], levels = decomposition_scenarios)
    ) |>
    # Channels that are zero everywhere (no social protection here) are dropped.
    dplyr::filter(max(abs(value)) > 1e-6, .by = channel)
}
