# Fig 2: number of surveys per country (standalone script).
# Boundaries: World Bank Official Boundaries, version 3 (Data Catalog dataset
# 0038272, last updated 2026-10-21), public parquet files. Country polygons
# (Admin 0) are filled; non-determined legal status areas (NDLSA) are drawn on
# top as grey polygons with a dashed outline. The download is simplified and
# cached in data/boundaries/; delete the .gpkg files to download again.
# Run from the project root.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(sf)
})
for (f in list.files("code/functions", pattern = "\\.R$", full.names = TRUE)) source(f)

check_batch("descriptives")

base_url <- paste0(
  "https://datacatalogfiles.worldbank.org/ddh-published/0038272/3/DR0096331/",
  "World%20Bank%20Official%20Boundaries%20%28Parquet%29/",
  "World%20Bank%20Official%20Boundaries%20-%20"
)
sources <- c(admin0 = "Admin%200", ndlsa = "NDLSA")

# Download one parquet layer, simplify it and store it as GeoPackage.
fetch_boundaries <- function(name) {
  path <- file.path("data", "boundaries", paste0("wb_", name, ".gpkg"))
  if (!file.exists(path)) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    tmp <- tempfile(fileext = ".parquet")
    on.exit(unlink(tmp))
    utils::download.file(paste0(base_url, sources[[name]], ".parquet"), tmp,
                         mode = "wb", quiet = TRUE)
    layer <- arrow::read_parquet(tmp)
    layer <- sf::st_sf(
      layer[setdiff(names(layer), "geometry")],
      geometry = sf::st_as_sfc(layer$geometry, crs = 4326)
    )
    suppressMessages(sf::sf_use_s2(FALSE))
    # The tolerance is in decimal degrees; sf warns about that for lon/lat data.
    layer <- suppressWarnings(sf::st_simplify(layer, preserveTopology = TRUE, dTolerance = 0.1))
    sf::write_sf(layer[c("ISO_A3", "NAM_0", "geometry")], path)
  }
  sf::read_sf(path)
}

admin0 <- fetch_boundaries("admin0")
ndlsa <- fetch_boundaries("ndlsa")

n_surveys <- wave_stats() |>
  filter(variable == "welfare") |>
  count(code, name = "n_surveys")

missing <- setdiff(n_surveys$code, admin0$ISO_A3)
if (length(missing) > 0) stop("No boundary polygon for: ", paste(missing, collapse = ", "))

robinson <- "+proj=robin"
map_data <- admin0 |>
  filter(ISO_A3 != "ATA") |>
  left_join(n_surveys, by = c("ISO_A3" = "code")) |>
  sf::st_transform(robinson)

ndlsa <- ndlsa |>
  sf::st_transform(robinson)

p <- ggplot() +
  geom_sf(data = map_data, aes(fill = n_surveys), colour = "white", linewidth = 0.1) +
  geom_sf(data = ndlsa, fill = "grey90", colour = "grey30", linewidth = 0.12,
          linetype = "dashed") +
  scale_fill_gradientn(
    colours = r2r_seq_ramp(5), na.value = "grey90", name = "Number of surveys",
    guide = guide_colourbar(barwidth = 12, barheight = 0.4, title.position = "top",
                            title.hjust = 0.5)
  ) +
  coord_sf(ylim = c(-6.6e6, NA), expand = FALSE) +
  theme_r2r() +
  theme(axis.text = element_blank(), panel.grid.major = element_blank())

save_r2r(
  p, "survey_map",
  map_data |> sf::st_drop_geometry() |> filter(!is.na(n_surveys)) |>
    select(code = ISO_A3, country = NAM_0, n_surveys) |> arrange(code),
  width = 16, height = 9
)
