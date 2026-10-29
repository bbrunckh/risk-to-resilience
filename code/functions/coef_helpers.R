# Coefficient extraction from model_terms (Fig 6, 7, C1 to C4).
# Rules carried over from legacy/03a_model_selection.R:
#   temperature, binned: coefficient of the top bin (relative to the coolest);
#   SPEI, binned: the driest bin is the omitted reference, so the coefficient of
#     the central bin is negated (driest relative to the central bin);
#   continuous: the coefficient of the variable itself.
# Model 3 is the model with covariates (Step 1 "fit3" of the legacy runs).

# Axis labels of the models spec: <var><months>_<form>, e.g. t3_bin, spei12_cust.
parse_axis_weather <- function(axis) {
  tibble::tibble(
    axis_weather = axis,
    wx_var = ifelse(grepl("^spei", axis), "spei6", "t"),
    ref_months = as.integer(stringr::str_extract(axis, "\\d+")),
    form = stringr::str_extract(axis, "[a-z]+$")
  )
}

ref_period_label <- function(months) {
  factor(
    ifelse(months == 1L, "1 month", paste0("1-", months, " months")),
    levels = c("1 month", "1-3 months", "1-6 months", "1-12 months")
  )
}

# Weather terms of the model-3 fits of a models run, with the axis labels.
# `axis_model` selects the models of the spec (lin, lin_urban, ...). RIF models
# have one row per quantile `tau`; `quantiles = TRUE` keeps those rows (and
# drops the mean rows, which are for `quantiles = FALSE`).
weather_terms <- function(axis_model = "lin", quantiles = FALSE) {
  models <- axis_model
  runs <- read_runs("models") |>
    dplyr::filter(.data$axis_model %in% models) |>
    dplyr::distinct(fit_id, axis_weather, axis_model)
  runs <- dplyr::left_join(runs, parse_axis_weather(unique(runs$axis_weather)), by = "axis_weather")
  read_table("models", "model_terms") |>
    dplyr::filter(model == 3L, is_weather, is.na(tau) != quantiles) |>
    dplyr::inner_join(runs, by = "fit_id")
}

# Bounds of a binned term "t(26.4, 27.4]" or "t(26.4, 27.4]:electricity".
add_bin_bounds <- function(terms) {
  terms |>
    dplyr::mutate(
      base = stringr::str_extract(term, "^[^:]+"),
      moderator = stringr::str_extract(term, "(?<=:).+$"),
      lower = as.numeric(stringr::str_extract(base, "(?<=\\()[-0-9.]+")),
      upper = as.numeric(stringr::str_extract(base, "(?<=, )[-0-9.]+(?=\\]$)"))
    )
}

# The extreme-bin coefficient of each fit (and each moderator, for interaction
# terms). Returns the same columns as `terms` plus `moderator`.
extreme_bin <- function(terms, interaction = FALSE) {
  has_colon <- grepl(":", terms$term, fixed = TRUE)
  binned <- terms |>
    dplyr::filter(form != "cont", has_colon == interaction) |>
    add_bin_bounds()
  out <- binned
  if (nrow(binned) > 0L) {
    top <- binned |>
      dplyr::group_by(fit_id, code, moderator, tau) |>
      dplyr::filter(upper == max(upper))
    central <- binned |>
      dplyr::group_by(fit_id, code, moderator, tau) |>
      dplyr::filter(upper < max(upper)) |>
      dplyr::arrange(lower, .by_group = TRUE) |>
      dplyr::slice(ceiling(dplyr::n() / 2)) |>
      dplyr::mutate(estimate = -estimate)
    out <- dplyr::bind_rows(
      dplyr::filter(top, wx_var == "t"),
      dplyr::filter(central, wx_var == "spei6")
    ) |>
      dplyr::ungroup()
  }
  if (!interaction) {
    cont <- terms |>
      dplyr::filter(form == "cont", term == wx_var) |>
      dplyr::mutate(moderator = NA_character_)
    out <- dplyr::bind_rows(out, cont)
  }
  out |>
    dplyr::mutate(sig = p_value < 0.05, lo = estimate - 1.96 * std_error,
                  hi = estimate + 1.96 * std_error)
}
