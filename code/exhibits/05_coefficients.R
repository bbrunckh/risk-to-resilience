# Fig 6, 7 and C1 to C4: weather coefficients by country (models project).
# Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("models")

# Fig 6, C1 to C4 ----

# Countries sorted by the 1-3 month coefficient, largest at the bottom.
ref_period_plot <- function(ex, wx, form) {
  x_label <- c(
    bin = c(t = "Coefficient on hottest bin (relative to coolest bin)",
            spei6 = "Coefficient on driest bin (relative to central bin)"),
    cust = c(t = "Coefficient on hottest bin (relative to lowest bin)",
             spei6 = "Coefficient on driest bin (relative to central bin)"),
    cont = c(t = "Coefficient on t (per degree C)", spei6 = "Coefficient on SPEI (per unit)")
  )[[paste(form, wx, sep = ".")]]
  # A standard error above 10 means the coefficient is not estimable (a bin with
  # almost no variation); it would stretch the axis, so it is left out and noted.
  not_estimable <- ex |> filter(std_error > 10)
  ex <- ex |>
    filter(!std_error > 10) |>
    mutate(ref_period = ref_period_label(ref_months)) |>
    left_join(
      ex |> filter(ref_months == 3L) |> select(code, sort_est = estimate),
      by = "code"
    ) |>
    mutate(code = forcats::fct_reorder(code, -sort_est))
  p <- ggplot(ex, aes(estimate, code, colour = sig)) +
    geom_r2r_zero() +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.3) +
    geom_point(size = 1.2) +
    scale_colour_r2r_sig() +
    scale_x_continuous(breaks = scales::breaks_extended(n = 4)) +
    facet_wrap(~ref_period, nrow = 1, scales = "free_x") +
    labs(x = x_label, y = NULL) +
    theme_r2r() +
    theme(panel.grid.major.y = element_blank())
  if (nrow(not_estimable) > 0) {
    p <- p +
      labs(caption = paste0(
        "Not shown, not estimable (standard error above 10): ",
        paste0(country_names[not_estimable$code], ", ",
               ref_period_label(not_estimable$ref_months), collapse = "; "), "."
      )) +
      theme(plot.caption = element_text(hjust = 0, colour = r2r_col$slate))
  }
  list(
    plot = p,
    data = ex |> arrange(ref_months, estimate) |>
      select(code, ref_period, term, estimate, std_error, lo, hi, p_value, sig),
    height = max(6, 2.6 + 0.32 * n_distinct(ex$code))
  )
}

all_terms <- weather_terms("lin")
for (wx in c("t", "spei6")) {
  for (form in c("bin", "cont", "cust")) {
    ex <- all_terms |>
      filter(wx_var == wx, .data$form == .env$form) |>
      extreme_bin()
    out <- ref_period_plot(ex, wx, form)
    save_r2r(out$plot, paste("coef_ref_period", wx, form, sep = "_"), out$data,
             width = 16, height = out$height)
  }
}

# Fig 7 ----

moderators <- c(
  urban = "Urban",
  electricity = "Access to electricity",
  imp_wat_san_rec = "Access to improved water & sanitation",
  educ_com2_hh = "Completed secondary education"
)
int <- weather_terms(c("lin_urban", "lin_elec", "lin_ws", "lin_ed")) |>
  filter(axis_weather == "t3_bin", wx_var == "t") |>
  extreme_bin(interaction = TRUE) |>
  filter(moderator %in% names(moderators))

# Countries sorted by the urban interaction; those without it come first.
urban_order <- int |> filter(moderator == "urban") |> arrange(estimate) |> pull(code)
other_order <- int |>
  filter(!code %in% urban_order) |>
  group_by(code) |>
  summarise(mean_est = mean(estimate), .groups = "drop") |>
  arrange(mean_est) |>
  pull(code)
int <- int |>
  mutate(
    code = factor(code, levels = c(other_order, urban_order)),
    moderator = factor(moderators[moderator], levels = moderators)
  )

p7 <- ggplot(int, aes(estimate, code, colour = sig)) +
  geom_r2r_zero() +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.3) +
  geom_point(size = 1.2) +
  scale_colour_r2r_sig() +
  scale_x_continuous(breaks = scales::breaks_extended(n = 4)) +
  facet_wrap(~moderator, nrow = 1, scales = "free_x", labeller = label_wrap_gen(22)) +
  labs(x = "Interaction coefficient", y = NULL) +
  theme_r2r() +
  theme(panel.grid.major.y = element_blank())
save_r2r(
  p7, "coef_interactions_t",
  int |> arrange(moderator, estimate) |>
    select(code, moderator, term, estimate, std_error, lo, hi, p_value, sig),
  width = 16, height = max(6, 2.6 + 0.32 * n_distinct(int$code))
)
