# Fig B1, B2: survey weather against the 1991-2020 reference period
# (descriptives project). Run from the project root.
# Two variable groups (temperature, precipitation) at the 3 and 12 month
# reference periods, as in the draft.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("descriptives")

wx_groups <- list(
  temperature = c(
    t = "Temperature mean (°C)",
    tr = "Tropical nights (Tmin >20°C)",
    tx35 = "Days max >35°C"
  ),
  precipitation = c(
    r = "Precipitation (mm)",
    rx5day = "Max 5-day precip (mm)",
    spei6 = "SPEI-6 (drought index)"
  )
)
profiles <- weather_profiles()

period_title <- function(months) paste(months, "month reference period")

plot_theme <- function() {
  theme_r2r() +
    theme(axis.text.x = element_text(angle = 30, hjust = 1), panel.grid.major.y = element_line(),
          plot.subtitle = element_text(face = "bold", colour = r2r_col$navy),
          plot.caption = element_text(hjust = 0, colour = r2r_col$slate))
}

# Fig B1: survey wave means against the reference period mean ----

survey_means <- function(labels, months) {
  d <- profiles |> filter(ref_months == months, variable %in% names(labels))
  waves <- d |> filter(source == "survey", wave != "All") |>
    transmute(code, year = as.integer(year), variable, mean)
  ref <- d |> filter(source == "historical", wave == "All") |>
    transmute(code, variable, ref_mean = mean)
  order <- waves |>
    filter(variable == names(labels)[1]) |>
    slice_max(year, by = code) |>
    arrange(mean) |>
    pull(code)
  waves |>
    left_join(ref, by = c("code", "variable")) |>
    mutate(variable = factor(labels[variable], levels = labels),
           country = factor(country_names[code], levels = country_names[order]))
}

for (group in names(wx_groups)) {
  for (months in c(3L, 12L)) {
    b1 <- survey_means(wx_groups[[group]], months)
    p <- ggplot(b1, aes(mean, country)) +
      geom_line(aes(group = country), colour = "grey70", linewidth = 0.3) +
      geom_point(aes(colour = year), size = 1.4, alpha = 0.9) +
      geom_point(aes(x = ref_mean), shape = "|", size = 3, colour = "grey30") +
      facet_wrap(~variable, nrow = 1, scales = "free_x") +
      scale_colour_gradientn(
        colours = r2r_seq_ramp(5), name = "Survey year",
        guide = guide_colourbar(barwidth = 14, barheight = 0.4, title.position = "top",
                                title.hjust = 0.5)
      ) +
      labs(
        x = NULL, y = NULL, subtitle = period_title(months),
        caption = "Filled circles = survey wave mean | Grey tick = climate reference period mean (1991-2020)"
      ) +
      plot_theme()
    save_r2r(p, paste0("weather_survey_mean_", group, "_", months, "m"),
             b1 |> arrange(variable, country, year) |>
               select(code, year, variable, survey_mean = mean, reference_mean = ref_mean),
             width = 16, height = max(6, 3 + 0.3 * n_distinct(b1$code)))
  }
}

# Fig B2: survey against reference period distribution ----

pct_cols <- c("p10", "p30", "p50", "p70", "p90")
survey_distribution <- function(labels, months) {
  d <- profiles |>
    filter(ref_months == months, wave == "All", variable %in% names(labels)) |>
    transmute(code, variable,
              source = if_else(source == "survey", "Survey (pooled waves)",
                               "Reference period (1991-2020)"),
              across(all_of(pct_cols)))
  order <- d |>
    filter(variable == names(labels)[1], source == "Survey (pooled waves)") |>
    arrange(p50) |>
    pull(code)
  d <- d |>
    mutate(variable = factor(labels[variable], levels = labels),
           y = match(code, order) + if_else(source == "Survey (pooled waves)", 0.18, -0.18))
  list(data = d, order = order)
}

for (group in names(wx_groups)) {
  res <- survey_distribution(wx_groups[[group]], 3L)
  d <- res$data
  order <- res$order
  p <- ggplot(d, aes(y = y, colour = source)) +
    geom_segment(aes(x = p10, xend = p90, yend = y), linewidth = 0.3, alpha = 0.6) +
    geom_segment(aes(x = p30, xend = p70, yend = y), linewidth = 1.4, alpha = 0.75) +
    geom_point(aes(x = p50), size = 1.3) +
    facet_wrap(~variable, nrow = 1, scales = "free_x") +
    scale_y_continuous(breaks = seq_along(order), labels = country_names[order],
                       expand = expansion(add = 0.8)) +
    scale_colour_manual(values = c("Survey (pooled waves)" = r2r_col$navy,
                                   "Reference period (1991-2020)" = "#B0B0B0")) +
    labs(
      x = NULL, y = NULL, subtitle = period_title(3L),
      caption = "Dot = median (p50) | Thick bar = p30-p70 | Thin line = p10-p90"
    ) +
    plot_theme()
  save_r2r(p, paste0("weather_distribution_", group, "_3m"),
           d |> arrange(variable, code, source) |> select(code, variable, source, all_of(pct_cols)),
           width = 16, height = max(6, 3 + 0.35 * length(order)))
}
