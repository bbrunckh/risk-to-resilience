# Fig 8, 9, C6, C7, C8: RIF (unconditional quantile) profiles of the extreme-bin
# coefficient, from the models project. Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("models")

quantile_scale <- scale_x_continuous(
  breaks = c(0.1, 0.3, 0.5, 0.7, 0.9), labels = paste0("p", c(10, 30, 50, 70, 90))
)

# Extreme-bin coefficient by quantile for the RIF models of `axis_model`,
# 1-3 month equal-frequency bins of `wx`.
rif_profile <- function(axis_model, wx, interaction = FALSE) {
  weather_terms(axis_model, quantiles = TRUE) |>
    filter(wx_var == wx, axis_weather == if (wx == "t") "t3_bin" else "spei3_bin") |>
    extreme_bin(interaction = interaction)
}

# The OLS mean of the same coefficient (linear model, same reference period).
ols_mean <- function(axis_model, wx, interaction = FALSE) {
  weather_terms(axis_model) |>
    filter(wx_var == wx, axis_weather == if (wx == "t") "t3_bin" else "spei3_bin") |>
    extreme_bin(interaction = interaction) |>
    select(code, ols = estimate)
}

# One panel per country: the profile with its 95% band and the OLS mean (all
# countries, Fig C6 to C8).
country_grid <- function(profile, ols, y_label) {
  d <- profile |> left_join(ols, by = "code")
  ggplot(d, aes(tau, estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = r2r_col$slate, linewidth = 0.3) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = r2r_col$blue, alpha = 0.15) +
    geom_hline(aes(yintercept = ols), colour = r2r_col$policy, linetype = "dotted",
               linewidth = 0.4) +
    geom_line(colour = r2r_col$blue, linewidth = 0.4) +
    geom_point(aes(shape = sig), colour = r2r_col$blue, size = 1) +
    scale_shape_manual(values = c("TRUE" = 16, "FALSE" = 1), guide = "none") +
    quantile_scale +
    facet_wrap(~code, ncol = 5, scales = "free_y") +
    labs(x = "Quantile", y = y_label,
         caption = "Blue = RIF coefficient with 95% band. Orange dotted = OLS mean. Filled = p < 0.05.") +
    theme_r2r() +
    theme(plot.caption = element_text(hjust = 0, colour = r2r_col$slate))
}

grid_height <- function(profile) 2.5 + 3.1 * ceiling(n_distinct(profile$code) / 5)

grid_data <- function(profile) {
  profile |> arrange(code, tau) |>
    select(code, tau, term, estimate, std_error, lo, hi, p_value, sig)
}

# Fig C6, C7, C8 ----

c6 <- rif_profile("rif", "t")
save_r2r(country_grid(c6, ols_mean("lin", "t"), "RIF coefficient, hottest bin"),
         "rif_profile_t_all", grid_data(c6), width = 16, height = grid_height(c6))

c7 <- rif_profile("rif", "spei6")
save_r2r(country_grid(c7, ols_mean("lin", "spei6"), "RIF coefficient, driest bin"),
         "rif_profile_spei6_all", grid_data(c7), width = 16, height = grid_height(c7))

c8 <- rif_profile("rif_elec", "t", interaction = TRUE) |> filter(moderator == "electricity")
save_r2r(
  country_grid(c8, ols_mean("lin_elec", "t", interaction = TRUE) , "Interaction coefficient"),
  "rif_profile_t_electricity_all", grid_data(c8), width = 16, height = grid_height(c8)
)

# Fig 8, 9: selected countries on one panel ----

selected_lines <- function(profile, countries, y_label) {
  d <- filter(profile, code %in% countries)
  last <- d |> filter(tau == max(tau))
  ggplot(d, aes(tau, estimate, colour = code, fill = code)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = r2r_col$slate, linewidth = 0.3) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.12, colour = NA) +
    geom_line(linewidth = 0.6) +
    geom_point(size = 1.2) +
    ggrepel::geom_text_repel(
      data = last, aes(label = code), hjust = 0, nudge_x = 0.02, direction = "y",
      size = 2.5, segment.colour = NA, seed = 123, show.legend = FALSE
    ) +
    scale_colour_manual(values = r2r_okabe_ito, guide = "none") +
    scale_fill_manual(values = r2r_okabe_ito, guide = "none") +
    scale_x_continuous(
      breaks = seq(0.1, 0.9, by = 0.1), labels = paste0("p", seq(10, 90, by = 10)),
      expand = expansion(mult = c(0.03, 0.1))
    ) +
    labs(x = "Welfare quantile", y = y_label,
         caption = "Shaded bands show approximate 95% confidence intervals.") +
    theme_r2r() +
    theme(plot.caption = element_text(hjust = 0, colour = r2r_col$slate))
}

fig8 <- c6 |> filter(code %in% c("BRA", "COL", "ZMB"))
save_r2r(selected_lines(c6, c("BRA", "COL", "ZMB"), "Coefficient on top temperature bin"),
         "rif_profile_t_selected", grid_data(fig8), width = 16, height = 9)

fig9 <- c8 |> filter(code %in% c("COL", "MWI", "TGO"))
save_r2r(selected_lines(c8, c("COL", "MWI", "TGO"), "Interaction of top temperature bin with electricity"),
         "rif_profile_t_electricity_selected", grid_data(fig9), width = 16, height = 9)

# Fig 12, 16, 19: profile by group ----
# From the regional (SEN) and cases (MWI, BRA) projects, when they exist.

group_cases <- tibble::tribble(
  ~project, ~country, ~axis_model, ~moderator, ~axis_weather, ~key,
  "regional", "SEN", "rif_elec", "electricity", NA, "rif_group_electricity_sen",
  "cases", "MWI", "rif_ed", "educ_com2_hh", "t_3m", "rif_group_secondary_education_mwi",
  "cases", "BRA", "rif_urban", "urban", "t_3m", "rif_group_urban_bra"
)
for (i in seq_len(nrow(group_cases))) {
  gc <- group_cases[i, ]
  if (!dir.exists(r2r_results_dir(gc$project))) next
  check_batch(gc$project)
  d <- group_profile(gc$project, gc$country, gc$axis_model, gc$moderator,
                     if (is.na(gc$axis_weather)) NULL else gc$axis_weather)
  if (is.null(d)) next
  save_r2r(group_profile_plot(d, gc$moderator), gc$key,
           d |> arrange(group, tau) |> select(code, tau, group, estimate, se, lo, hi),
           width = 8, height = 8.5)
}
