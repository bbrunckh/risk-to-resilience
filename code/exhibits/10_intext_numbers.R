# Every analysis number quoted in the report text that is not read off an
# exhibit. One row per number in output/tables/intext_numbers.csv: the report
# location and quoted text (code/intext_numbers.csv), the value this code and
# data produce, the source table and filter. The draft numbers are not targets.
# Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

have <- function(project) dir.exists(r2r_results_dir(project))
for (p in c("descriptives", "models", "regional", "cases")) if (have(p)) check_batch(p)

# A number that cannot be computed is reported as such, not dropped.
safe <- function(expr) {
  tryCatch(expr, error = function(e) paste("not available:", conditionMessage(e)))
}
fmt <- function(x, digits = 1) formatC(x, format = "f", digits = digits)
named <- function(code, x, digits = 1, suffix = "") {
  paste(paste0(code, " ", fmt(x, digits), suffix), collapse = "; ")
}
count_of <- function(flag, code, total = length(flag)) {
  paste0(sum(flag), " of ", total, " (", paste(code[flag], collapse = ", "), ")")
}

runs_regional <- if (have("regional")) sim_runs("regional")
runs_cases <- if (have("cases")) sim_runs("cases")

# Poverty headcount of the baseline arm at a return period (percentage points).
headcount <- function(runs, scen, rp) {
  d <- read_table(attr(runs, "project"), "summary") |>
    filter(sim_id == runs$sim_id[1], section == "adverse_year", metric == "headcount_ratio",
           group == "coefficient", scenario == scen, return_period == rp)
  if (nrow(d) == 0L) stop("no simulation results for run ", runs$run_id[1], " (see failures)")
  d$estimate * 100
}
with_project <- function(runs, project) {
  attr(runs, "project") <- project
  runs
}

# Countries with a negative expected policy effect on poverty, SSP3 2025-2035.
policy_effect_count <- function(axis_policy_key, variable = NA) {
  r <- runs_regional |> filter(axis_policy == axis_policy_key, poverty_line == 3.0)
  if (!is.na(variable)) {
    done <- latest_access("regional", variable) |> filter(share > 0.95) |> pull(code)
    r <- r |> filter(!code %in% done)
  }
  eff <- read_table("regional", "summary") |>
    filter(policy_id %in% r$policy_id, section == "policy_expected", measure == "effect",
           group == "intermodel", metric == "headcount_ratio", scenario == future_2030)
  paste0(count_of(eff$estimate < 0, eff$code), "; effect in pp: ",
         named(eff$code, eff$estimate * 100, 2))
}

# Linear models: top-bin t at 1-3 months and driest-bin SPEI.
lin <- weather_terms("lin")
t_bin <- lin |> filter(wx_var == "t", form == "bin", ref_months == 3L) |> extreme_bin()
spei_bin <- lin |> filter(wx_var == "spei6", form == "bin") |> extreme_bin()
moderators <- weather_terms(c("lin_urban", "lin_elec")) |>
  filter(axis_weather == "t3_bin", wx_var == "t") |>
  extreme_bin(interaction = TRUE)

latest_wave <- function(variable_name, column) {
  wave_stats() |>
    filter(variable == variable_name) |>
    slice_max(year, by = code) |>
    transmute(code, value = .data[[column]])
}
min_max <- function(d, digits = 1, scale = 1) {
  paste0("min ", d$code[which.min(d$value)], " ", fmt(min(d$value) * scale, digits),
         "; max ", d$code[which.max(d$value)], " ", fmt(max(d$value) * scale, digits))
}

n_hh <- wave_stats() |> filter(variable == "welfare")
dates <- read_table("descriptives", "interview_dates") |> filter(is.na(month))
matched <- weather_profiles() |>
  filter(source == "survey", wave != "All", variable == "t", ref_months == 3L)
case_codes <- c("SEN", "MWI", "BRA")

values <- list()

values$N01 <- safe({
  r <- with_project(runs_regional |> filter(axis_policy == "none", poverty_line == 3.0,
                                           code == "SEN"), "regional")
  hist <- headcount(r, "Historical", "1:1")
  paste0("1-in-20 year minus historical typical year, pp: SSP3 2025-2035 ",
         fmt(headcount(r, future_2030, "1:20") - hist), "; SSP3 2040-2060 ",
         fmt(headcount(r, future_2050, "1:20") - hist))
})
values$N02 <- safe(paste0(n_distinct(country_regions[unique(n_hh$code)]), " regions (",
                          paste(sort(unique(country_regions[unique(n_hh$code)])), collapse = ", "), ")"))
values$N03 <- safe(paste0(count_of(t_bin$estimate < 0 & t_bin$sig, t_bin$code),
                          " with a negative significant top-bin coefficient"))
values$N04 <- values$N15 <- safe({
  top <- t_bin |> arrange(estimate) |> slice_head(n = 3)
  paste("three most negative top-bin coefficients:", named(top$code, top$estimate, 3))
})
values$N05 <- values$N16 <- safe({
  harm <- spei_bin |>
    summarise(n_sig_neg = sum(sig & estimate < 0), n = n(), .by = code)
  paste0("significant negative driest-bin coefficient in every reference period: ",
         paste(harm$code[harm$n_sig_neg == harm$n], collapse = ", "),
         "; in some: ", paste(harm$code[harm$n_sig_neg > 0 & harm$n_sig_neg < harm$n],
                              collapse = ", "))
})
values$N06 <- safe(policy_effect_count("cash_p10"))
values$N07 <- safe({
  d <- weather_terms("rif_elec", quantiles = TRUE) |>
    filter(axis_weather == "t3_bin", wx_var == "t") |>
    extreme_bin(interaction = TRUE) |>
    filter(moderator == "electricity", code %in% c("MWI", "TGO", "COL"), tau %in% c(0.1, 0.3, 0.5))
  paste(paste0(d$code, " p", d$tau * 100, " ", fmt(d$estimate, 3),
               ifelse(d$sig, "*", "")), collapse = "; ")
})
values$N08 <- safe(policy_effect_count("elec", "electricity"))
values$N09 <- safe(policy_effect_count("ws", "imp_wat_san_rec"))
values$N10 <- safe(policy_effect_count("secondary", "educ_com2_hh"))
values$N11 <- safe(paste0(format(sum(n_hh$n), big.mark = ","), " households, ", nrow(n_hh),
                          " waves, ", n_distinct(n_hh$code), " countries"))
values$N12 <- safe(min_max(latest_wave("poor300", "mean"), 1, 100))
values$N13 <- safe(min_max(latest_wave("welfare", "p50"), 2))
values$N14 <- safe(paste(vapply(c("electricity", "imp_wat_san_rec", "educ_com2_hh"), function(v) {
  paste0(v, ": ", paste(latest_access("descriptives", v) |> filter(share > 0.95) |> pull(code),
                        collapse = ", "))
}, ""), collapse = "; "))
values$N17 <- safe({
  d <- moderators |> filter(moderator == "urban")
  paste0("positive significant: ", paste(d$code[d$sig & d$estimate > 0], collapse = ", "),
         "; negative significant: ", paste(d$code[d$sig & d$estimate < 0], collapse = ", "))
})
values$N18 <- safe({
  d <- moderators |> filter(moderator == "electricity")
  paste(paste0(d$code, " ", fmt(d$estimate, 3), " (se ", fmt(d$std_error, 3), ")"),
        collapse = "; ")
})
values$N19 <- safe({
  d <- weather_terms("rif", quantiles = TRUE) |>
    filter(axis_weather == "t3_bin", wx_var == "t") |>
    extreme_bin() |>
    filter(code %in% c("BRA", "ZMB", "COL"), tau %in% c(0.1, 0.5, 0.9))
  paste(paste0(d$code, " p", d$tau * 100, " ", fmt(d$estimate, 3)), collapse = "; ")
})
values$N20 <- safe({
  ols <- moderators |> filter(moderator == "electricity") |> select(code, ols_p = p_value)
  rif <- weather_terms("rif_elec", quantiles = TRUE) |>
    filter(axis_weather == "t3_bin", wx_var == "t") |>
    extreme_bin(interaction = TRUE) |>
    filter(moderator == "electricity") |>
    summarise(rif_sig = any(sig), .by = code)
  hidden <- inner_join(ols, rif, by = "code") |> filter(ols_p >= 0.05, rif_sig)
  paste0(nrow(hidden), " countries (", paste(hidden$code, collapse = ", "), ")")
})
values$N21 <- safe({
  d <- climate_effects(runs_regional |> filter(axis_policy == "none", poverty_line == 3.0),
                       "median") |> filter(return_period == "1:1")
  paste0("lower median welfare in ", count_of(d$central < 0, d$code))
})
values$N22 <- safe({
  p3 <- climate_effects(runs_regional |> filter(axis_policy == "none", poverty_line == 3.0),
                        "poverty") |> filter(return_period == "1:1")
  p83 <- climate_effects(runs_regional |> filter(axis_policy == "none", poverty_line == 8.3),
                         "poverty") |> filter(return_period == "1:1")
  g <- climate_effects(runs_regional |> filter(axis_policy == "none", poverty_line == 8.3),
                       "gini") |> filter(return_period == "1:1")
  paste0("higher poverty at 3.00: ", count_of(p3$central > 0, p3$code),
         "; at 8.30: ", count_of(p83$central > 0, p83$code),
         "; Gini higher in ", count_of(g$central > 0, g$code))
})
values$N23 <- "whiskers are the ensemble p10-p90 (summary, group ensemble), not min-max"
values$N24 <- safe({
  r <- with_project(runs_regional |> filter(axis_policy == "none", poverty_line == 3.0,
                                           code == "SEN"), "regional")
  paste0("typical year SSP3 2040-2060 minus historical, pp: ",
         fmt(headcount(r, future_2050, "1:1") - headcount(r, "Historical", "1:1"), 2))
})
# Resilience effect (repositioning + interaction), in percentage points of
# welfare summed over deciles: deciles 1-4, deciles 5-10, and the share of the
# total in deciles 1-4 when all deciles have the same sign.
res_share <- function(d) {
  if (is.null(d)) stop("no decomposition for this run")
  d |>
    filter(channel %in% c("Resilience: repositioning", "Resilience: interaction")) |>
    summarise(pct = sum(pct), .by = c(scenario, decile)) |>
    summarise(low = sum(pct[decile <= 4]), high = sum(pct[decile > 4]),
              same_sign = all(pct >= 0) || all(pct <= 0), .by = scenario) |>
    mutate(text = paste0(
      scenario, ": deciles 1-4 ", fmt(low, 2), " pp, deciles 5-10 ", fmt(high, 2), " pp",
      if_else(same_sign, paste0(" (", fmt(100 * low / (low + high), 0), "% in deciles 1-4)"), "")
    ))
}
values$N25 <- safe(paste(res_share(decomposition_1in20("regional", "SEN", "elec"))$text,
                         collapse = "; "))
values$N26 <- safe(paste(res_share(decomposition_1in20("cases", "MWI", "secondary"))$text,
                         collapse = "; "))
bra <- function(weather) runs_cases |> filter(code == "BRA", axis_weather == weather)
# Fail with a clear message when a table has no rows (for example the run's
# simulation failed): safe() then reports the number as not available.
need_rows <- function(d, what) {
  if (nrow(d) == 0L) stop("no ", what, " (see failures.parquet of the project)")
  d
}
values$N27 <- safe({
  tm <- read_table("cases", "policy_measures") |>
    filter(policy_id == bra("t_3m")$policy_id, section == "transfer_amount") |>
    need_rows("transfer amount")
  paste(paste0(tm$measure, " ", fmt(tm$value, 2)), collapse = "; ")
})
values$N28 <- safe({
  r <- with_project(bra("t_3m"), "cases")
  paste0("BRA poverty at 8.30, historical: 1-in-20 ", fmt(headcount(r, "Historical", "1:20")),
         "%; typical ", fmt(headcount(r, "Historical", "1:1")), "%")
})
bra_policy <- function(weather) {
  r <- bra(weather)
  hist <- with_project(r, "cases") |> headcount("Historical", "1:1")
  read_table("cases", "summary") |>
    filter(policy_id == r$policy_id, section == "policy_threshold", metric == "headcount_ratio",
           measure == "Equal-model mean", return_period %in% c("1:1", "1:20")) |>
    need_rows("policy results") |>
    mutate(pp_vs_hist = (estimate - hist / 100) * 100)
}
values$N29 <- safe({
  d <- bra_policy("t_3m") |> filter(scenario == future_2030, group == "Policy")
  paste(paste0("with transfer ", d$return_period, ": ", fmt(d$pp_vs_hist, 1),
               " pp vs historical typical year"), collapse = "; ")
})
values$N30 <- safe({
  d <- bra_policy("t_3m") |>
    select(scenario, return_period, group, estimate) |>
    tidyr::pivot_wider(names_from = group, values_from = estimate) |>
    mutate(gap_pp = (Baseline - Policy) * 100)
  paste(paste0(d$scenario, " ", d$return_period, ": ", fmt(d$gap_pp, 1), " pp"), collapse = "; ")
})
values$N31 <- safe({
  d <- group_profile("cases", "BRA", "rif_urban", "urban", "t_3m") |>
    filter(tau %in% c(0.1, 0.3, 0.5, 0.9))
  paste(paste0(d$group, " p", d$tau * 100, " ", fmt(d$estimate, 3), " [", fmt(d$lo, 3), ", ",
               fmt(d$hi, 3), "]"), collapse = "; ")
})
values$N32 <- safe({
  z <- n_hh |> filter(code == "ZMB")
  paste0("ZMB households per wave: ", paste(z$year, z$n, sep = " ", collapse = "; "),
         "; ratio of the largest wave to the mean of the others ",
         fmt(max(z$n) / mean(z$n[z$n != max(z$n)]), 1))
})
values$N33 <- "see output/tables/table_f1.csv"
values$N34 <- safe(paste(dates |> filter(code %in% case_codes) |>
                           transmute(t = paste0(code, " ", year, ": ", n_dates, " interview months")) |>
                           pull(t), collapse = "; "))
values$N36 <- safe(paste0("BRA locations per wave (n_locations): ",
                          paste(dates |> filter(code == "BRA") |> transmute(t = paste(year, n_locations)) |>
                                  pull(t), collapse = "; "),
                          "; admin2 count is not in the batch tables"))
values$N37 <- safe({
  m <- matched |> filter(code %in% case_codes)
  paste0("households matched to weather (t, 1-3 months): ",
         fmt(100 * sum(m$n) / sum(n_hh$n[n_hh$code %in% case_codes]), 1), "% of households in ",
         paste(case_codes, collapse = ", "))
})
values$N38 <- safe(paste(n_hh |> filter(code %in% case_codes) |>
                           transmute(t = paste0(code, " ", year, ": ", n)) |> pull(t),
                         collapse = "; "))

out <- utils::read.csv("code/intext_numbers.csv", stringsAsFactors = FALSE) |>
  mutate(value = vapply(id, function(i) as.character(values[[i]] %||% "not computed"), "")) |>
  select(id, report_location, quoted_text, quantity, value, source_table, filter,
         poverty_line)
utils::write.csv(out, r2r_output_dir("tables", "intext_numbers.csv"), row.names = FALSE)
cli::cli_alert_success("{nrow(out)} numbers; {sum(grepl('^not (available|computed)', out$value))} not available")
