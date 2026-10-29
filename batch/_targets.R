library(targets)

# Shared by the four projects: TAR_PROJECT (see _targets.yaml) names the project,
# whose spec is batch/<project>/spec.yaml and whose tables go to results/<project>/.
project <- Sys.getenv("TAR_PROJECT", "")
if (!project %in% c("descriptives", "models", "regional", "cases")) {
  stop("Set TAR_PROJECT to descriptives, models, regional or cases.", call. = FALSE)
}

# Workers share this machine: set WISEAPP_BATCH_WORKERS and, on a shared host,
# WISEAPP_BATCH_MEMORY_GB. The Step 2 simulation and Step 3 policy runs hold
# hundreds of MB each, so they run on their own, smaller set of workers
# (WISEAPP_BATCH_SIM_WORKERS).
workers <- as.integer(Sys.getenv("WISEAPP_BATCH_WORKERS", "1"))
sim_workers <- as.integer(Sys.getenv("WISEAPP_BATCH_SIM_WORKERS", "1"))
memory_gb <- Sys.getenv("WISEAPP_BATCH_MEMORY_GB", "")

tar_option_set(
  packages = "wiseapp",
  error = "continue",
  memory = "transient",
  garbage_collection = TRUE,
  controller = wiseapp::wise_batch_controller(
    workers = workers,
    sim_workers = sim_workers,
    memory_gb = if (nzchar(memory_gb)) as.numeric(memory_gb)
  )
)

# The policy runs start from the stored Step 2 run of their simulation (hundreds
# of MB each, in the store's user/sims/). keep_step2 = FALSE deletes them after
# the run (phase 3 full run).
wiseapp::wise_targets(
  file.path("batch", project, "spec.yaml"),
  out_dir = file.path("results", project),
  keep_step2 = FALSE
)
