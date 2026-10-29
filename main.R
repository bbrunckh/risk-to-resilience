# main.R - From Risk to Resilience: reproducibility package
#
# See README.md for full instructions to replicate.
#
# Default (RUN_BATCH <- FALSE): rebuilds every exhibit from the aggregate tables
# in results/ (minutes, no restricted data).
# Full run (RUN_BATCH <- TRUE): first re-runs the four batch projects from the
# WISE-APP data folder (about 12 hours; needs WISEAPP_DATA_PATH), then the
# exhibits.

# ---- Settings (the only lines to change) -------------------------------------

# Package folder. By default the working directory, which must be the folder
# that holds this file.
root <- getwd()

# FALSE: exhibits from results/. TRUE: run the batch projects first.
RUN_BATCH <- FALSE

# Parallel workers of the batch (full run only). One simulation worker needs up
# to 10 GB (Brazil about 40 GB); raise it only on a large machine.
Sys.setenv(
  WISEAPP_BATCH_WORKERS = Sys.getenv("WISEAPP_BATCH_WORKERS", "1"),
  WISEAPP_BATCH_SIM_WORKERS = Sys.getenv("WISEAPP_BATCH_SIM_WORKERS", "1")
)

# Simulation workers per project (full run). cases runs with one worker because
# one Brazil simulation needs about 40 GB: it runs alone.
sim_workers <- c(descriptives = "4", models = "4", regional = "4", cases = "1")

# ---- Environment -------------------------------------------------------------

if (!file.exists(file.path(root, "main.R"))) {
  stop("Set `root` to the package folder (the folder that holds main.R).", call. = FALSE)
}
setwd(root)

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
# Activate the project library explicitly: a user profile may disable renv's
# autoloader, and then the restore would install into the shared user library.
renv::load(root)
renv::restore(prompt = FALSE)

# ---- Batch projects (full run) -----------------------------------------------

if (RUN_BATCH) {
  if (!nzchar(Sys.getenv("WISEAPP_DATA_PATH"))) {
    stop("RUN_BATCH is TRUE: set WISEAPP_DATA_PATH to the WISE-APP data folder (see README).",
         call. = FALSE)
  }
  # macOS caps the R heap at physical RAM; the Brazil simulation needs more
  # (it then uses swap). Inherited by the batch processes started below.
  # Windows R crashes at startup when this is set (checked on R 4.5.3, exit code
  # -1073741819), so it is set on macOS and Linux only.
  if (.Platform$OS.type != "windows") {
    Sys.setenv(R_MAX_VSIZE = Sys.getenv("R_MAX_VSIZE", "Inf"))
  }

  # One project at a time. Finished branches are kept in _targets/, so a rerun
  # resumes after a crash. Failed branches are logged, not fatal.
  for (project in names(sim_workers)) {
    Sys.setenv(TAR_PROJECT = project, WISEAPP_BATCH_SIM_WORKERS = sim_workers[[project]])
    targets::tar_make()
  }
}

# ---- Check the aggregate tables ----------------------------------------------

sums_file <- file.path("results", "SHA256SUMS")
if (file.exists(sums_file)) {
  sums <- utils::read.table(sums_file, colClasses = "character", quote = "", comment.char = "")
  now <- vapply(
    sums[[2]], function(f) digest::digest(file = file.path("results", f), algo = "sha256"), ""
  )
  if (any(now != sums[[1]])) {
    warning("results/ files differ from SHA256SUMS: ", paste(sums[[2]][now != sums[[1]]], collapse = ", "),
            call. = FALSE)
  } else {
    message("results/ matches SHA256SUMS (", nrow(sums), " files).")
  }
} else if (!RUN_BATCH) {
  warning("results/SHA256SUMS not found: table integrity not checked.", call. = FALSE)
}

# ---- Exhibits ----------------------------------------------------------------

# Each script is standalone: it sources code/functions/, reads results/ and
# reports the batch failures of the projects it uses. Figures go to
# output/figures/, plotted values to output/figure_data/, tables and in-text
# numbers to output/tables/.
for (f in list.files(file.path("code", "exhibits"), pattern = "^[0-9]{2}_.*\\.R$", full.names = TRUE)) {
  message("Running ", f)
  source(f, local = new.env())
}
