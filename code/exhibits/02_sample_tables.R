# Table A1, Table F1 and Fig F1: survey sample and interview dates
# (descriptives project). Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("descriptives")

# One row per survey wave ----

waves <- wave_stats() |>
  filter(variable == "welfare") |>
  select(code, year, survname, households = n)

# Interview dates: the wave total row has `month` NA.
dates <- read_table("descriptives", "interview_dates") |>
  mutate(year = as.integer(year))
totals <- dates |>
  filter(is.na(month)) |>
  select(code, year, interview_months = n_dates, locations = n_locations)

# Households matched to weather: the survey rows of weather_stats at the main
# reference period (1-3 months), household level, for t.
matched <- weather_profiles() |>
  filter(source == "survey", wave != "All", variable == "t", ref_months == 3L) |>
  transmute(code, year = as.integer(year), households_matched = n,
            pct_matched = 100 - pct_missing)

sample_waves <- waves |>
  left_join(totals, by = c("code", "year")) |>
  left_join(matched, by = c("code", "year")) |>
  mutate(country = country_names[code]) |>
  arrange(country, year) |>
  select(country, code, year, survey = survname, households, locations, pct_matched,
         interview_months)

# Tables are named by the report label and use the column names of the report.
# Counts are whole numbers, the matched share has one decimal.
write_table_csv <- function(x, key) {
  utils::write.csv(x, r2r_output_dir("tables", paste0(r2r_file_stem(key), ".csv")),
                   row.names = FALSE, na = "")
}

# Table A1
write_table_csv(
  sample_waves |>
    transmute(
      Country = country, `Survey year` = as.integer(year),
      `Number of households` = as.integer(households),
      `Number of locations` = as.integer(locations),
      `% Weather matched` = round(pct_matched, 1),
      `Number of Interview months` = as.integer(interview_months)
    ),
  "table_survey_waves"
)

# Table F1: the three case-study countries of Annex F ----

f1_codes <- c("SEN", "MWI", "BRA")
table_f1 <- sample_waves |>
  filter(code %in% f1_codes) |>
  left_join(matched |> select(code, year, households_matched), by = c("code", "year")) |>
  arrange(match(code, f1_codes), year) |>
  transmute(
    `Country Survey-Year` = paste(country, year),
    `Number of Households` = as.integer(households),
    `Number of Unique Months for Interviews` = as.integer(interview_months),
    `Number of Unique Locations` = as.integer(locations),
    `Number of households matched to weather data` =
      paste0(as.integer(households_matched), " (", round(100 * households_matched / households), "%)")
  )
write_table_csv(table_f1, "table_interview_dates_cases")

# Fig F1: monthly interview incidence ----

incidence <- dates |>
  filter(!is.na(month), code %in% f1_codes) |>
  mutate(share = n / sum(n), .by = c(code, year)) |>
  mutate(
    country = factor(country_names[code], levels = country_names[f1_codes]),
    wave = factor(year)
  )

p_f1 <- ggplot(incidence, aes(factor(month, levels = 1:12), share, fill = wave)) +
  geom_col(position = position_dodge(preserve = "single", width = 0.8), width = 0.7) +
  facet_wrap(~country, nrow = 1) +
  scale_x_discrete(drop = FALSE, labels = month.abb) +
  scale_y_continuous(labels = scales::label_percent()) +
  scale_fill_manual(values = r2r_okabe_ito) +
  labs(x = "Interview month", y = "Share of households interviewed") +
  guides(fill = guide_legend(nrow = 1)) +
  theme_r2r() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), panel.grid.major.x = element_blank())
save_r2r(p_f1, "interview_incidence",
         incidence |> arrange(code, year, month) |>
           select(code, year, month, households = n, share),
         width = 16, height = 7)
