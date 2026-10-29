# Fig A1, A2, A3: survey sample (descriptives project).
# Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("descriptives")

# Fig A1: interview months against locations, shaded by % geocoded ----

waves <- wave_stats() |> filter(variable == "welfare")
geo <- wave_stats("with_loc") |>
  filter(variable == "welfare") |>
  select(code, year, n_geo = n)
dates <- read_table("descriptives", "interview_dates") |>
  filter(is.na(month)) |>
  transmute(code, year = as.integer(year), n_months = n_dates, n_locations)

a1 <- waves |>
  select(code, year, n) |>
  left_join(geo, by = c("code", "year")) |>
  left_join(dates, by = c("code", "year")) |>
  mutate(pct_geocoded = 100 * n_geo / n, label = paste(code, year))

p_a1 <- ggplot(a1, aes(n_locations, n_months)) +
  geom_point(aes(colour = pct_geocoded), size = 1.8, alpha = 0.85) +
  ggrepel::geom_text_repel(
    aes(label = label), size = 2, max.overlaps = 30, colour = r2r_col$slate,
    segment.colour = "grey70", segment.size = 0.2, min.segment.length = 0.2
  ) +
  scale_colour_gradientn(
    colours = r2r_seq_ramp(5), name = "% observations geocoded",
    labels = scales::label_number(suffix = "%"),
    guide = guide_colourbar(barwidth = 12, barheight = 0.4, title.position = "top",
                            title.hjust = 0.5)
  ) +
  scale_x_log10() +
  labs(x = "Number of geocoded locations (log scale)", y = "Number of interview months") +
  theme_r2r()
save_r2r(p_a1, "survey_months_locations",
         a1 |> select(code, year, n_locations, n_months, pct_geocoded),
         width = 16, height = 11)

# Fig A2: welfare metrics by wave ----

metric_levels <- c(
  "Mean welfare\n(PPP/day)", "Median welfare\n(PPP/day)", "Gini", "Poverty $3.00", "Poverty $8.30"
)
a2 <- bind_rows(
  wave_stats() |>
    filter(variable == "welfare") |>
    transmute(code, year, `Mean welfare\n(PPP/day)` = mean, `Median welfare\n(PPP/day)` = p50,
              Gini = gini) |>
    tidyr::pivot_longer(-c(code, year), names_to = "metric", values_to = "value"),
  wave_stats() |>
    filter(variable %in% c("poor300", "poor830")) |>
    transmute(code, year, metric = if_else(variable == "poor300", "Poverty $3.00", "Poverty $8.30"),
              value = mean)
)
# Countries sorted by mean welfare of the latest wave, highest at the top.
country_order <- a2 |>
  filter(metric == metric_levels[1]) |>
  slice_max(year, by = code) |>
  arrange(value) |>
  pull(code)
a2 <- a2 |>
  mutate(metric = factor(metric, levels = metric_levels),
         country = factor(country_names[code], levels = country_names[country_order]))

p_a2 <- ggplot(a2, aes(value, country)) +
  geom_line(aes(group = country), colour = "grey70", linewidth = 0.3) +
  geom_point(aes(colour = year), size = 1.4, alpha = 0.9) +
  facet_wrap(~metric, nrow = 1, scales = "free_x") +
  scale_colour_gradientn(
    colours = r2r_seq_ramp(5), name = "Survey year",
    guide = guide_colourbar(barwidth = 14, barheight = 0.4, title.position = "top",
                            title.hjust = 0.5)
  ) +
  labs(x = NULL, y = NULL) +
  theme_r2r() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1), panel.grid.major.y = element_line())
save_r2r(p_a2, "survey_welfare_metrics",
         a2 |> arrange(metric, country, year) |>
           transmute(code, year, metric = gsub("\n", " ", metric), value),
         width = 16, height = max(6, 3 + 0.3 * n_distinct(a2$code)))

# Fig A3: policy variables by wave ----

policy_labels <- c(
  electricity = "Electricity access",
  imp_wat_san_rec = "Improved water & sanitation",
  educ_com2_hh = "Secondary education"
)
a3 <- wave_stats() |>
  filter(variable %in% names(policy_labels)) |>
  transmute(code, year, variable, mean, low_coverage = pct_missing > 10)
policy_order <- a3 |>
  filter(variable == "electricity") |>
  slice_max(year, by = code) |>
  arrange(mean) |>
  pull(code)
policy_order <- c(setdiff(unique(a3$code), policy_order), policy_order)
a3 <- a3 |>
  mutate(variable = factor(policy_labels[variable], levels = policy_labels),
         country = factor(country_names[code], levels = country_names[policy_order]))

p_a3 <- ggplot(a3, aes(mean, country)) +
  geom_line(aes(group = country), colour = "grey70", linewidth = 0.3) +
  geom_point(aes(colour = year), size = 1.6, alpha = 0.9) +
  geom_point(data = filter(a3, low_coverage), shape = 21, colour = "red", size = 1.6,
             stroke = 0.5) +
  facet_wrap(~variable, nrow = 1, scales = "free_x") +
  scale_colour_gradientn(
    colours = r2r_seq_ramp(5), name = "Survey year",
    guide = guide_colourbar(barwidth = 14, barheight = 0.4, title.position = "top",
                            title.hjust = 0.5)
  ) +
  labs(x = NULL, y = NULL, caption = "Red outline = >10% observations missing values") +
  theme_r2r() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1), panel.grid.major.y = element_line(),
        plot.caption = element_text(hjust = 0, colour = r2r_col$slate))
save_r2r(p_a3, "survey_policy_variables",
         a3 |> arrange(variable, country, year) |>
           select(code, year, variable, share = mean, low_coverage),
         width = 16, height = max(6, 3 + 0.3 * n_distinct(a3$code)))
