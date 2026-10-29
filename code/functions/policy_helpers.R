# Helpers for the Step 2 and Step 3 results of the regional and cases projects
# (Fig 10 to 20). Rules carried over from legacy/04a_climate_sim_results.R:
#   return periods 1:1, 1:10, 1:20 for every metric: in the batch `summary` the
#   return period is in the adverse direction of the metric, so 1:20 is the bad
#   year (high poverty, low median welfare). The legacy runs stored median
#   welfare the other way round and used 9:10 and 19:20; not needed here;
#   relative difference = (value - historical central) / |historical central| x 100,
#   the historical central being the value at the same return period.
# Bars are the ensemble p10-p90 stored in `summary` (the draft used min-max).

return_periods <- list(
  poverty = c("1:1", "1:10", "1:20"),
  gini = c("1:1", "1:10", "1:20"),
  median = c("1:1", "1:10", "1:20")
)

return_period_labels <- c(
  "1:1" = "Typical\n(median)\ntemperature",
  "1:10" = "1-in-10\nyear\ntemperature",
  "1:20" = "1-in-20\nyear\ntemperature"
)

# Summary metric name of a plotted metric.
summary_metric <- c(poverty = "headcount_ratio", gini = "gini", median = "median")

future_2030 <- "SSP3-7.0 / 2025-2035"
future_2050 <- "SSP3-7.0 / 2040-2060"

# Runs of a Step 2/3 project with the stage ids and the axis labels.
sim_runs <- function(project) {
  read_runs(project) |>
    dplyr::select(run_id, code = axis_country, axis_model, axis_policy, poverty_line,
                  sim_id, policy_id, dplyr::any_of("axis_weather"))
}

relative_difference <- function(value, reference) (value - reference) / abs(reference) * 100

# Climate effect of the baseline arm: future scenario against the historical
# central estimate at the same return period (Fig 10, C5). `runs` selects the
# simulations (one per country).
climate_effects <- function(runs, metric_key, scenario = future_2030) {
  rps <- return_periods[[metric_key]]
  metric_name <- summary_metric[[metric_key]]
  s <- read_table("regional", "summary") |>
    dplyr::filter(sim_id %in% runs$sim_id, section == "adverse_year", metric == metric_name,
                  return_period %in% rps)
  hist <- s |>
    dplyr::filter(scenario == "Historical", group == "coefficient") |>
    dplyr::select(sim_id, code, return_period, hist = estimate)
  s |>
    dplyr::filter(scenario == !!scenario, group == "ensemble") |>
    dplyr::inner_join(hist, by = c("sim_id", "code", "return_period")) |>
    dplyr::transmute(
      code, return_period, metric = metric_key,
      central = relative_difference(estimate, hist),
      lo = relative_difference(lo, hist), hi = relative_difference(hi, hist)
    )
}

# Policy against its own baseline arm, both relative to the historical
# baseline (Fig 11, 14, 15, 18). `runs` selects the policy runs (one per
# country); the baseline arm is the same simulation without the policy.
policy_effects <- function(runs, metric_key, scenario = future_2030) {
  rps <- return_periods[[metric_key]]
  metric_name <- summary_metric[[metric_key]]
  summaries <- read_table("regional", "summary")
  s <- summaries |>
    dplyr::filter(policy_id %in% runs$policy_id, section == "policy_threshold",
                  metric == metric_name, return_period %in% rps)
  # Historical central: the baseline arm of the same simulation. (The
  # "Single historical estimate" of policy_threshold is empty at 1:10 and 1:20.)
  hist <- summaries |>
    dplyr::filter(sim_id %in% runs$sim_id, section == "adverse_year", metric == metric_name,
                  scenario == "Historical", group == "coefficient",
                  return_period %in% rps) |>
    dplyr::inner_join(dplyr::distinct(runs, sim_id, policy_id), by = "sim_id",
                      suffix = c("_base", "")) |>
    dplyr::select(policy_id, code, return_period, hist = estimate)
  s |>
    dplyr::filter(scenario == !!scenario) |>
    dplyr::inner_join(hist, by = c("policy_id", "code", "return_period")) |>
    dplyr::mutate(rel = relative_difference(estimate, hist)) |>
    dplyr::select(policy_id, code, return_period, arm = group, measure, rel) |>
    tidyr::pivot_wider(names_from = measure, values_from = rel) |>
    dplyr::transmute(
      code, return_period, metric = metric_key,
      arm = factor(arm, levels = c("Baseline", "Policy")),
      central = `Equal-model mean`, lo = `Ensemble P10`, hi = `Ensemble P90`
    )
}

# Share of households with a policy variable in the latest wave, to leave out
# countries where universal access changes nothing (baseline share above 95%).
latest_access <- function(project, variable_name) {
  read_table(project, "variable_stats") |>
    dplyr::filter(wave != "All", sample == "all", variable == variable_name) |>
    dplyr::distinct(code, wave, .keep_all = TRUE) |>
    dplyr::slice_max(as.integer(year), by = code) |>
    dplyr::select(code, share = mean)
}

# One dot per country and return period, bars the ensemble p10-p90.
return_period_panels <- function(d, x_label, colour_by, colours, labels = ggplot2::waiver()) {
  d <- d |>
    dplyr::mutate(
      return_period = factor(return_period_labels[return_period],
                             levels = return_period_labels[names(return_period_labels) %in% return_period])
    )
  ggplot2::ggplot(d, ggplot2::aes(central, country, colour = .data[[colour_by]])) +
    geom_r2r_zero() +
    ggplot2::geom_linerange(ggplot2::aes(xmin = lo, xmax = hi), linewidth = 0.4, alpha = 0.6,
                            position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::geom_point(size = 1.4, position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::facet_wrap(~return_period, nrow = 1, scales = "free_x") +
    ggplot2::scale_colour_manual(values = colours, labels = labels) +
    ggplot2::labs(x = x_label, y = NULL) +
    theme_r2r() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_line())
}
