# Fig 13, 17: decile decomposition of a policy effect in the 1-in-20 year
# (decomposition table of the regional and cases projects). The 1-in-20 year
# rule is in code/functions/decomposition_helpers.R. Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

decomposition_plot <- function(d) {
  ggplot(d, aes(factor(decile), pct, fill = channel)) +
    geom_col(width = 0.72, colour = "white", linewidth = 0.2) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = r2r_col$slate) +
    facet_wrap(~scenario, nrow = 1) +
    scale_fill_manual(values = decomposition_colours, drop = TRUE) +
    scale_y_continuous(labels = scales::label_number(suffix = "%", accuracy = 0.1)) +
    labs(x = "Welfare decile (1 = poorest)", y = "Change in welfare") +
    theme_r2r() +
    theme(panel.grid.major.x = element_blank())
}

cases <- tibble::tribble(
  ~project, ~country, ~policy, ~key,
  "regional", "SEN", "elec", "decomposition_electricity_sen",
  "cases", "MWI", "secondary", "decomposition_secondary_education_mwi"
)

for (i in seq_len(nrow(cases))) {
  cs <- cases[i, ]
  if (!dir.exists(r2r_results_dir(cs$project))) next
  check_batch(cs$project)
  d <- decomposition_1in20(cs$project, cs$country, cs$policy)
  if (is.null(d)) next
  save_r2r(decomposition_plot(d), cs$key,
           d |> arrange(scenario, decile, channel) |>
             select(scenario, weather_year = sim_year, decile, channel, pct),
           width = 16, height = 9)
}
