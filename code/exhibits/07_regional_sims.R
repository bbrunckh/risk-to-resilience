# Fig 10, 11, 14, 15, 18 and C5: climate and policy effects by country
# (regional project, SSP3-7.0 2025-2035). Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("regional")
runs <- sim_runs("regional")

# Countries ordered by the central estimate at 1:1, largest at the top.
country_factor <- function(d, order_by) {
  order <- order_by |> filter(return_period == "1:1") |> arrange(central) |> pull(code)
  d |> mutate(country = factor(code, levels = unique(c(setdiff(d$code, order), order))))
}

# Fig 10 and C5: climate effect, no policy ----

climate_plot <- function(runs_use, metric_key) {
  d <- climate_effects(runs_use, metric_key)
  is_worse <- if (metric_key == "median") d$central < 0 else d$central > 0
  d <- d |>
    mutate(change = factor(if_else(is_worse, "Worse", "Better"), levels = c("Better", "Worse"))) |>
    country_factor(d)
  p <- return_period_panels(
    d, "Relative difference in SSP3 2030 climate scenario (%)", "change",
    c(Better = r2r_col$better, Worse = r2r_col$worse)
  )
  list(plot = p, data = d |> arrange(return_period, desc(central)) |>
         select(code, return_period, central, lo, hi, change))
}

no_policy_3 <- runs |> filter(axis_policy == "none", poverty_line == 3.0)
no_policy_830 <- runs |> filter(axis_policy == "none", poverty_line == 8.3)

for (spec in list(
  list("climate_median_welfare", no_policy_3, "median"),
  list("climate_poverty_300", no_policy_3, "poverty"),
  list("climate_poverty_830", no_policy_830, "poverty"),
  list("climate_gini_830", no_policy_830, "gini")
)) {
  if (nrow(spec[[2]]) == 0L) next
  out <- climate_plot(spec[[2]], spec[[3]])
  save_r2r(out$plot, paste0("regional_", spec[[1]]), out$data, width = 16,
           height = 3.5 + 0.45 * n_distinct(out$data$code))
}

# Fig 11, 14, 15, 18: policy against no policy, poverty at $3.00 ----

policies <- tibble::tribble(
  ~key, ~axis_policy, ~variable, ~label,
  "electricity", "elec", "electricity", "Universal electricity access",
  "water_sanitation", "ws", "imp_wat_san_rec", "Universal improved water and sanitation",
  "secondary_education", "secondary", "educ_com2_hh", "Universal secondary education",
  "cash_transfer", "cash_p10", NA_character_, "Cash transfer (bottom 40%, P10)"
)

for (i in seq_len(nrow(policies))) {
  pol <- policies[i, ]
  runs_use <- runs |> filter(axis_policy == pol$axis_policy, poverty_line == 3.0)
  if (!is.na(pol$variable)) {
    # Countries where more than 95% already have access are left out.
    done <- latest_access("regional", pol$variable) |> filter(share > 0.95) |> pull(code)
    runs_use <- runs_use |> filter(!code %in% done)
  }
  if (nrow(runs_use) == 0L) next
  d <- policy_effects(runs_use, "poverty")
  arms <- c(Baseline = "No policy", Policy = pol$label)
  d <- d |>
    country_factor(filter(d, arm == "Baseline")) |>
    mutate(arm = factor(arms[as.character(arm)], levels = arms))
  p <- return_period_panels(
    d, "Relative difference from historical (%)", "arm",
    setNames(c(r2r_col$baseline, r2r_col$policy), arms)
  )
  save_r2r(p, paste0("regional_poverty_", pol$key),
           d |> arrange(return_period, arm, desc(central)) |>
             select(code, return_period, arm, central, lo, hi),
           width = 16, height = 3.5 + 0.55 * n_distinct(d$code))
}
