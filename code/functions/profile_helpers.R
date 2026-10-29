# Group profiles of the RIF top-bin coefficient (Fig 12, 16, 19).
# The group without the characteristic has the top-bin coefficient b; the group
# with it has b + g, g being the interaction term. The band is 1.96 x the
# standard error from model_vcov: var(b + g) = var(b) + var(g) + 2 cov(b, g).

group_profile <- function(project, country, axis_model, moderator, axis_weather = NULL) {
  runs <- read_runs(project) |>
    dplyr::filter(axis_country == country, .data$axis_model == !!axis_model)
  if (!is.null(axis_weather)) runs <- dplyr::filter(runs, .data$axis_weather == !!axis_weather)
  if (nrow(runs) == 0L) {
    return(NULL)
  }
  fit <- runs$fit_id[1]
  terms <- read_table(project, "model_terms") |>
    dplyr::filter(fit_id == fit, model == 3L, is_weather, !is.na(tau))
  main <- terms |>
    dplyr::filter(!grepl(":", term, fixed = TRUE)) |>
    dplyr::mutate(upper = as.numeric(stringr::str_extract(term, "(?<=, )[-0-9.]+(?=\\]$)")))
  top <- main$term[which.max(main$upper)]
  inter <- paste0(top, ":", moderator)
  vcov <- read_table(project, "model_vcov") |>
    dplyr::filter(fit_id == fit)
  pick <- function(t1, t2) {
    vcov |>
      dplyr::filter(term_1 == t1, term_2 == t2) |>
      dplyr::select(tau, covariance)
  }
  coefs <- terms |>
    dplyr::filter(term %in% c(top, inter)) |>
    dplyr::select(tau, term, estimate) |>
    tidyr::pivot_wider(names_from = term, values_from = estimate) |>
    dplyr::rename(b = dplyr::all_of(top), g = dplyr::all_of(inter)) |>
    dplyr::left_join(dplyr::rename(pick(top, top), var_b = covariance), by = "tau") |>
    dplyr::left_join(dplyr::rename(pick(inter, inter), var_g = covariance), by = "tau") |>
    dplyr::left_join(dplyr::rename(pick(top, inter), cov_bg = covariance), by = "tau")
  dplyr::bind_rows(
    coefs |> dplyr::transmute(tau, group = "without", estimate = b, se = sqrt(var_b)),
    coefs |> dplyr::transmute(tau, group = "with", estimate = b + g,
                              se = sqrt(var_b + var_g + 2 * cov_bg))
  ) |>
    dplyr::mutate(code = country, lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)
}

group_labels <- list(
  electricity = c(with = "Access to electricity", without = "No access to electricity"),
  educ_com2_hh = c(with = "Completed secondary", without = "Not completed secondary"),
  urban = c(with = "Urban", without = "Rural")
)

group_profile_plot <- function(d, moderator) {
  labels <- group_labels[[moderator]]
  d <- dplyr::mutate(d, group = factor(labels[group], levels = labels))
  ggplot2::ggplot(d, ggplot2::aes(tau, estimate, colour = group, fill = group)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = r2r_col$slate,
                        linewidth = 0.3) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::geom_point(size = 1.4) +
    ggplot2::scale_colour_manual(values = stats::setNames(c(r2r_col$better, r2r_col$worse),
                                                          labels)) +
    ggplot2::scale_fill_manual(values = stats::setNames(c(r2r_col$better, r2r_col$worse),
                                                        labels)) +
    ggplot2::scale_x_continuous(breaks = seq(0.1, 0.9, by = 0.2),
                                labels = paste0("p", seq(10, 90, by = 20))) +
    ggplot2::labs(x = "Welfare quantile", y = "RIF coefficient, top temperature bin") +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 1),
                    fill = ggplot2::guide_legend(nrow = 1)) +
    theme_r2r()
}
