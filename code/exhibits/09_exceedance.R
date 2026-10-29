# Fig 20: exceedance curves of the poverty rate, historical against SSP3 with
# and without a policy (annual table of the cases project). Run from the
# project root.
#
# Curve of a weather-year series: values sorted from the worst year, exceedance
# probability rank / (n + 1) (Weibull). The future curve is the median across
# climate-model members of the member curves on common probabilities.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

n_years <- 30L
common_probs <- seq(1 / (n_years + 1), n_years / (n_years + 1), length.out = n_years)

exceedance_curve <- function(x) {
  x <- sort(x, decreasing = TRUE)
  tibble::tibble(value = x, exceed_prob = seq_along(x) / (length(x) + 1))
}

# Median across members of the member curves, on common probabilities.
future_curve <- function(d) {
  d |>
    reframe(exceedance_curve(value), .by = c(scenario, arm, member)) |>
    filter(n() >= 2, .by = c(scenario, arm, member)) |>
    reframe(
      exceed_prob = common_probs,
      value = approx(exceed_prob, value, xout = common_probs, rule = 2)$y,
      .by = c(scenario, arm, member)
    ) |>
    summarise(value = median(value), .by = c(scenario, arm, exceed_prob))
}

exceedance_data <- function(project, country, axis_policy, axis_weather, policy_label) {
  run <- sim_runs(project) |>
    filter(code == country, axis_policy == .env$axis_policy, !is.na(policy_id))
  if (!is.null(axis_weather)) run <- filter(run, .data$axis_weather == .env$axis_weather)
  if (nrow(run) == 0L) {
    return(NULL)
  }
  annual <- read_table(project, "annual") |>
    filter(sim_id == run$sim_id[1], metric == "headcount_ratio") |>
    mutate(arm = if_else(is.na(policy_id), "No policy", policy_label))
  annual <- annual |> filter(is.na(policy_id) | policy_id == run$policy_id[1])
  if (nrow(annual) == 0L) {
    cli::cli_alert_warning("{country}: no simulation results (see failures), no exceedance curve")
    return(NULL)
  }
  hist <- annual |>
    filter(scenario == "Historical", arm == "No policy") |>
    summarise(value = mean(value), .by = sim_year) |>
    reframe(exceedance_curve(value))
  fut <- annual |>
    filter(scenario %in% c(future_2030, future_2050)) |>
    summarise(value = mean(value), .by = c(scenario, arm, member, sim_year)) |>
    future_curve()
  list(hist = hist, fut = fut, line = run$poverty_line[1])
}

exceedance_plot <- function(d, country, policy_label) {
  scen_label <- c(future_2030, future_2050)
  names(scen_label) <- c("SSP3 2030", "SSP3 2050")
  fut <- d$fut |>
    filter(exceed_prob <= 0.5) |>
    mutate(
      label = paste(arm, names(scen_label)[match(scenario, scen_label)], sep = " - "),
      kind = if_else(arm == "No policy", "No policy", "Policy"),
      period = names(scen_label)[match(scenario, scen_label)]
    )
  hist <- d$hist |> filter(exceed_prob <= 0.5)
  ends <- bind_rows(
    fut |> slice_max(exceed_prob, by = label) |>
      transmute(exceed_prob, y = value, label, kind),
    hist |> slice_max(exceed_prob) |>
      transmute(exceed_prob, y = value, label = "Historical (no policy)", kind = "Historical")
  )
  colours <- c("No policy" = r2r_col$baseline, Policy = r2r_col$policy, Historical = "#000000")
  ggplot() +
    geom_line(data = fut, aes(exceed_prob, value, colour = kind, linetype = period,
                              group = label), linewidth = 0.6) +
    geom_line(data = hist, aes(exceed_prob, value), colour = "#000000", linewidth = 0.7) +
    ggrepel::geom_text_repel(
      data = ends, aes(exceed_prob, y, label = label, colour = kind), direction = "y",
      hjust = 0, nudge_x = 0.15, size = 2.3, segment.size = 0.2, segment.colour = "grey60",
      min.segment.length = 0, show.legend = FALSE
    ) +
    scale_x_log10(
      name = "Event frequency (years)", breaks = c(1 / 20, 1 / 10, 1 / 5, 1 / 2),
      labels = c("1-in-20", "1-in-10", "1-in-5", "1-in-2"), expand = expansion(mult = c(0.01, 0.2))
    ) +
    scale_y_continuous(
      name = paste0("Poverty rate ($", fmt_line(d$line), "/day, 2021 PPP)"),
      labels = scales::percent_format(accuracy = 0.1)
    ) +
    scale_colour_manual(values = colours) +
    scale_linetype_manual(values = c("SSP3 2030" = "solid", "SSP3 2050" = "dashed")) +
    coord_cartesian(clip = "off") +
    theme_r2r() +
    theme(legend.position = "none", plot.margin = margin(4, 70, 4, 4))
}

fmt_line <- function(x) formatC(x, format = "f", digits = 2)

cases <- tibble::tribble(
  ~project, ~country, ~axis_policy, ~axis_weather, ~label, ~key,
  "cases", "BRA", "cash_p5", "t_3m", "Cash transfer", "exceedance_poverty_830_bra"
)
for (i in seq_len(nrow(cases))) {
  cs <- cases[i, ]
  if (!dir.exists(r2r_results_dir(cs$project))) next
  check_batch(cs$project)
  d <- exceedance_data(cs$project, cs$country, cs$axis_policy, cs$axis_weather, cs$label)
  if (is.null(d)) next
  save_r2r(
    exceedance_plot(d, cs$country, cs$label), cs$key,
    bind_rows(
      d$hist |> mutate(scenario = "Historical", arm = "No policy"),
      d$fut
    ) |> select(scenario, arm, exceed_prob, value),
    width = 16, height = 9
  )
}
