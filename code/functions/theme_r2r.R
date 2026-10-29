# Shared figure theme and output helper (PLAN.md section 7).
# Colours are the WISE-APP brand tokens of wise-app/R/utils_plot_theme.R,
# copied as values (those objects are internal to wiseapp).

r2r_col <- list(
  navy = "#002244", blue = "#0071BC", charcoal = "#1D2A35", slate = "#5B6B79",
  grid = "#E3E9EE",
  baseline = "#5B6B79", policy = "#D55E00", history = "#808080", ssp3 = "#0072B2",
  better = "#0072B2", worse = "#D55E00",
  sig = "#0072B2", not_sig = "#808080"
)

# Okabe-Ito in the order of the app (.okabe_ito).
r2r_okabe_ito <- c(
  "#0072B2", "#D55E00", "#009E73", "#A86400", "#2F8FCB", "#CC79A7", "#8C8200", "#000000"
)

# Brand blue ramp for sequential fills.
r2r_seq_ramp <- function(n) {
  grDevices::colorRampPalette(c("#D9EFF8", "#0071BC", "#002244"))(n)
}

# Open Sans is used when its files are in data/fonts/; otherwise the system
# sans font is used (the output then depends on the installed fonts).
r2r_font_family <- function() {
  files <- list.files("data/fonts", pattern = "OpenSans.*\\.ttf$", full.names = TRUE)
  if (length(files) == 0L) {
    return("sans")
  }
  systemfonts::register_font(
    "Open Sans",
    plain = grep("Regular", files, value = TRUE)[1],
    bold = grep("Bold\\.ttf$", files, value = TRUE)[1]
  )
  "Open Sans"
}

theme_r2r <- function(base_size = 8) {
  ggplot2::theme_minimal(base_size = base_size, base_family = r2r_font_family()) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = r2r_col$charcoal),
      axis.text = ggplot2::element_text(colour = r2r_col$charcoal),
      axis.title = ggplot2::element_text(colour = r2r_col$navy),
      strip.text = ggplot2::element_text(face = "bold", colour = r2r_col$navy),
      panel.grid.major = ggplot2::element_line(colour = r2r_col$grid, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(4, 6, 4, 4)
    )
}

# Zero and reference lines: slate, dashed.
geom_r2r_zero <- function(xintercept = 0) {
  ggplot2::geom_vline(
    xintercept = xintercept, linetype = "dashed", colour = r2r_col$slate, linewidth = 0.3
  )
}

scale_colour_r2r_sig <- function() {
  ggplot2::scale_colour_manual(
    values = c("TRUE" = r2r_col$sig, "FALSE" = r2r_col$not_sig),
    labels = c("TRUE" = "p < 0.05", "FALSE" = "n.s."),
    breaks = c("FALSE", "TRUE")
  )
}

# Output folders under output/.
r2r_output_dir <- function(...) {
  path <- file.path("output", ...)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  path
}

# File stem of an exhibit from its report label in code/exhibit_map.csv:
# "Figure 6 (panel 1)" -> "figure_6_1", "Table A1" -> "table_a1". Exhibits
# without a number (in-text numbers) keep their key.
r2r_file_stem <- function(key) {
  map <- utils::read.csv("code/exhibit_map.csv", stringsAsFactors = FALSE)
  label <- map$label[match(key, map$key)]
  if (is.na(label)) stop("No entry in code/exhibit_map.csv for: ", key)
  m <- regmatches(label, regexec("^(Figure|Table) ([A-Z]?[0-9]+)(?: \\(panel ([0-9]+)\\))?$",
                                 label, perl = TRUE))[[1]]
  if (length(m) == 0) return(key)
  tolower(paste(c(m[2], m[3], if (nzchar(m[4])) m[4]), collapse = "_"))
}

# Save a figure (PNG at 300 dpi) and the plotted values (CSV), both named by the
# report label (see r2r_file_stem).
# Sizes in cm: full width 16 x 9, half width 8 x 7 (height may grow with rows).
save_r2r <- function(plot, key, data, width = 16, height = 9) {
  stem <- r2r_file_stem(key)
  png <- r2r_output_dir("figures", paste0(stem, ".png"))
  ggplot2::ggsave(png, plot, width = width, height = height, units = "cm", dpi = 300,
                  device = ragg::agg_png, bg = "white")
  utils::write.csv(data, r2r_output_dir("figure_data", paste0(stem, ".csv")), row.names = FALSE)
  invisible(png)
}
