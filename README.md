# From Risk to Resilience: reproducibility package

## Overview

This package reproduces results in **From Risk to Resilience: Insights on the Impacts of Climate and Climate Policies on Welfare** by Ben Brunckhorst, Miki Khanh Doan, Erwin Knippenberg, Alejandro de la Fuente, Daniel Kryger and Mads Hoefer.

The report estimates how weather shocks change household welfare in 21 countries (60 survey waves), simulates welfare under future climate (CMIP6, SSP3-7.0) and evaluates four adaptation policies. All estimation and simulation runs through the batch pipeline of the R package [`wiseapp`](https://github.com/worldbank/wise-app) (`wiseapp::wise_targets()`), which is bundled in this package. The exhibit scripts read only the aggregate tables that the pipeline writes to `results/` and draw all figures with one shared theme.

The package has two tiers. **One click runs tier 2 by default.**

| Tier | What it does | Needs | Runtime |
|---|---|---|---|
| **2. Exhibits from aggregate tables (default)** | Rebuilds every listed results figure and table and the in-text number inventory from the included `results/` tables; external-source exceptions are listed below | This package only (no restricted data) | minutes |
| **1. Full run** | Re-runs the four batch projects from the household surveys, weather and climate projections, then tier 2 | The WISE-APP data folder (restricted, see Data Availability) and a large machine | about 12 hours on the reference workstation (see Runtime) |

The `results/` tables contain aggregates only (no household records). Their SHA-256 checksums are in `results/SHA256SUMS`.

Output filenames follow report labels (for example `figure_11.png`). See the List of Exhibits below.

---

## Data Availability

- [ ] All data are publicly available.
- [x] Some data cannot be made publicly available.
- [ ] No data can be made publicly available.

The household survey microdata and the location lookup built from their geocodes are restricted. They are needed only for the full run (tier 1). Tier 2 uses the aggregate batch tables in `results/` and the public boundary files in `data/boundaries/`. 

### Data Sources

The package starts from the WISE-APP data folder ("usable data"). It is built by the code in the repository [`worldbank/wise-app-data`](https://github.com/worldbank/wise-app-data), which documents the raw sources and the processing steps. A copy of the repository at that commit is deposited with the data. The folder is deposited in DDH as one restricted archive, "Data for WISE-APP":  `wiseapp_data_r2r.zip`, which holds only the files this package needs (the surveys of the 21 countries, their historical weather, and the projections of the 13 simulated countries). Folder structure, expected file names and checksums are in `data/README.md`.

- **Name:** GMD household surveys with geocodes (21 countries, 60 waves), WISE-APP extract (household files `microdata/hh/`)
  - **Source:** World Bank Global Monitoring Database (GMD), harmonized household surveys with spatial identifiers. Extract built by `steps/gmd_surveys.R` of `wise-app-data`.
  - **Access:** Restricted. Deposited on 28 October 2026 in the World Bank Development Data Hub (DDH) as a restricted dataset: "WISE-APP data for Risk to Resilience Report", https://datacatalog.worldbank.org/int/data/dataset/0067211/wiseapp_data_for_risk_to_resilience_report. Request access through DDH.
  - **Files:** `microdata/hh/<CODE>/<CODE>_<year>_<survey>_GMD_hh.parquet`. SHA-256 of every file used: `data/SHA256SUMS`.
  - **Citation:** World Bank. 2026. *Global Monitoring Database (GMD)* World Bank, Washington, DC. WISE-APP extract: "WISE-APP data for Risk to Resilience Report", DDH dataset 0067211, https://datacatalog.worldbank.org/int/data/dataset/0067211/wiseapp_data_for_risk_to_resilience_report.

- **Name:** H3 location lookup (`microdata/h3/<CODE>/<CODE>_<year>_<survey>_GMD_h3.parquet`)
  - **Source:** Built from the GMD geocodes, with GHS-POP 2020 weights, by `steps/gmd_surveys.R` of `wise-app-data`.
  - **Access:** Restricted, deposited with the survey extract.
  - **Citation:** Schiavina, M., S. Freire, and K. MacManus. 2023. *GHS-POP R2023A - GHS population grid multitemporal (1975-2030)*. European Commission, Joint Research Centre (JRC). https://doi.org/10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE. For the geocoded survey locations, see the GMD citation above.

- **Name:** CPI and PPP conversion factors (`metadata/cpi_ppp.csv`)
  - **Source:** World Bank Poverty and Inequality Platform, auxiliary tables `cpi` and `ppp` (2021 PPP), downloaded with the `pipr` R package by `steps/cpi_ppp.R`.
  - **URL:** https://pip.worldbank.org
  - **Access date:** 2026-10-23
  - **License:** CC-BY 4.0. File deposited in DDH with the data folder.
  - **Citation:** World Bank. 2026. *Poverty and Inequality Platform* (version 20260922_2021) [Data set]. World Bank Group. https://pip.worldbank.org/. Auxiliary tables `cpi` and `ppp` (2021 PPP). Accessed 23 October 2026.

- **Name:** Monthly weather by H3 cell, 1991-2020 reference period and survey years (`hazard/weather/historical/<CODE>/<CODE>_era5land.parquet`; variables `t`, `tr`, `tx35`, `r`, `rx5day`, `spei6`)
  - **Source:** ERA5-Land monthly variables and indices from the CDS "Gridded dataset underpinning the Copernicus Interactive Climate Atlas" (`multi-origin-c3s-atlas`), processed by `steps/era5land.R` of `wise-app-data`.
  - **URL:** https://cds.climate.copernicus.eu/datasets/multi-origin-c3s-atlas; DOI: https://doi.org/10.24381/cds.h35hb680
  - **Access date:** processed 23 October 2026
  - **License:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
  - **Citation:** Copernicus Climate Change Service, Climate Data Store. 2024. *Gridded dataset underpinning the Copernicus Interactive Climate Atlas*. https://doi.org/10.24381/cds.h35hb680. Accessed 23 October 2026. See also Muñoz-Sabater, J., et al. 2021. "ERA5-Land: a state-of-the-art global reanalysis dataset for land applications." *Earth System Science Data* 13: 4349-4383. https://doi.org/10.5194/essd-13-4349-2021. 

- **Name:** CMIP6 climate projections by H3 cell (`hazard/weather/projections/<CODE>/<CODE>_cmip6_ssp370.parquet` and `<CODE>_cmip6_historical.parquet`; scenario SSP3-7.0, ensemble of models). 
  - **Source:** CMIP6 monthly variables and indices from the same CDS "Gridded dataset underpinning the Copernicus Interactive Climate Atlas" (`multi-origin-c3s-atlas`), processed by `steps/cmip6.R` of `wise-app-data`.
  - **URL:** https://cds.climate.copernicus.eu/datasets/multi-origin-c3s-atlas; DOI: https://doi.org/10.24381/cds.h35hb680
  - **Access date:** processed 23 October 2026
  - **License:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) 
  - **Citation:** Copernicus Climate Change Service, Climate Data Store. 2024. *Gridded dataset underpinning the Copernicus Interactive Climate Atlas*. https://doi.org/10.24381/cds.h35hb680. Accessed 23 October 2026. See also Eyring, V., et al. 2016. "Overview of the Coupled Model Intercomparison Project Phase 6 (CMIP6) experimental design and organization." *Geoscientific Model Development* 9: 1937-1958. https://doi.org/10.5194/gmd-9-1937-2016. O'Neill, B. C., et al. 2016. "The Scenario Model Intercomparison Project (ScenarioMIP) for CMIP6." *Geoscientific Model Development* 9: 3461-3482. https://doi.org/10.5194/gmd-9-3461-2016.

- **Name:** World Bank Official Boundaries, Admin 0 (Figure 2)
  - **Source:** World Bank Data Catalog, dataset 0038272, World Bank Official Boundaries, version 3 (last updated 2026-10-21), public parquet files `World Bank Official Boundaries - Admin 0.parquet` (country polygons) and `World Bank Official Boundaries - NDLSA.parquet` (non-determined legal status areas), under `https://datacatalogfiles.worldbank.org/ddh-published/0038272/3/DR0096331/`.
  - **URL:** https://datacatalog.worldbank.org/search/dataset/0038272/World-Bank-Official-Boundaries
  - **Access date:** 2026-10-28
  - **License:** CC BY 4.0
  - **Citation:** World Bank. 2026. *World Bank Official Boundaries*, version 3 (Admin 0 and NDLSA). World Bank Data Catalog, dataset 0038272. https://datacatalog.worldbank.org/search/dataset/0038272/World-Bank-Official-Boundaries. Accessed 28 October 2026.
  - **Included in the package:** simplified copy in `data/boundaries/` (`wb_admin0.gpkg`, `wb_ndlsa.gpkg`). `01_map.R` downloads them again only if these files are deleted.

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.

The package includes only aggregate tables derived from the restricted data (`results/`).

---

## Instructions for Replicators

### One click: exhibits from the aggregate tables (default)

1. Unzip the package. Open R (or Positron or RStudio) in the package folder.
2. Run `main.R` (`source("main.R")` or `Rscript main.R` from the package folder).

`main.R` restores the R environment with `renv`, checks the `results/` checksums, then runs the ten exhibit scripts (each reports the batch failure log of the projects it reads). Figures go to `output/figures/`, plotted values to `output/figure_data/`, tables and in-text numbers to `output/tables/`. No restricted data and no internet are needed after the packages are installed (the first `renv::restore()` needs internet).

Run from the package folder so that `root <- getwd()` in `main.R` resolves correctly. A writable local disk rather than a synced folder is recommended to avoid synchronization delays or file-locking issues.

### Optional: full run from the household data

1. Get `wiseapp_data_r2r.zip` from DDH (see Data Availability) and unzip it to a local disk. The zip has no wrapper folder: it unpacks to `hazard/`, `metadata/` and `microdata/`, so unzip it into a new folder. Do not run from a synced OneDrive folder: reads of files on demand are slow. Optionally check the files against `data/SHA256SUMS`.
2. Set the environment variable `WISEAPP_DATA_PATH` to that folder (for example in `~/.Renviron`: `WISEAPP_DATA_PATH=/path/to/wiseapp-data`).
3. In `main.R`, change `RUN_BATCH <- FALSE` to `RUN_BATCH <- TRUE`.
4. Run `main.R`.

`main.R` then runs the projects one at a time in the order `descriptives`, `models`, `regional`, `cases`, and continues with the exhibits. The environment used by each run (R, wiseapp, duckdb, `renv.lock` checksum, survey file checksums) is recorded in `results/<project>/manifest.json`. A finished branch is kept in `_targets/`, so after a crash (out of memory, sleep, reboot) rerunning `main.R` resumes where it stopped.

After the full run, restore `RUN_BATCH <- FALSE` for normal tier-2 use. 

Expected results of a full run (reference run, 28 to 29 October 2026): 0 failures in `descriptives` and `cases`; 16 in `models` and 3 in `regional`. All 19 are expected and come from the data.

---

## List of Exhibits

The code reproduces all tables and figures in the paper that present results from the analysis.

Conceptual exhibits are not reproduced because they contain no analysis results: Figures 1, 3, 4, 5, 21 and Table B1 (list of available weather variables). 

All listed results figures and tables can be reproduced from the included aggregate material (tier 2), without restricted microdata.

| Exhibit | Output | Script |
|---|---|---|
| Figure 2 | `output/figures/figure_2.png` | `code/exhibits/01_map.R` |
| Figure 6 (panel 1) | `output/figures/figure_6_1.png` | `code/exhibits/05_coefficients.R` |
| Figure 6 (panel 2) | `output/figures/figure_6_2.png` | `code/exhibits/05_coefficients.R` |
| Figure 7 | `output/figures/figure_7.png` | `code/exhibits/05_coefficients.R` |
| Figure 8 | `output/figures/figure_8.png` | `code/exhibits/06_rif_profiles.R` |
| Figure 9 | `output/figures/figure_9.png` | `code/exhibits/06_rif_profiles.R` |
| Figure 10 (panel 1) | `output/figures/figure_10_1.png` | `code/exhibits/07_regional_sims.R` |
| Figure 10 (panel 2) | `output/figures/figure_10_2.png` | `code/exhibits/07_regional_sims.R` |
| Figure 11 | `output/figures/figure_11.png` | `code/exhibits/07_regional_sims.R` |
| Figure 12 | `output/figures/figure_12.png` | `code/exhibits/06_rif_profiles.R` |
| Figure 13 | `output/figures/figure_13.png` | `code/exhibits/08_decomposition.R` |
| Figure 14 | `output/figures/figure_14.png` | `code/exhibits/07_regional_sims.R` |
| Figure 15 | `output/figures/figure_15.png` | `code/exhibits/07_regional_sims.R` |
| Figure 16 | `output/figures/figure_16.png` | `code/exhibits/06_rif_profiles.R` |
| Figure 17 | `output/figures/figure_17.png` | `code/exhibits/08_decomposition.R` |
| Figure 18 | `output/figures/figure_18.png` | `code/exhibits/07_regional_sims.R` |
| Figure 19 | `output/figures/figure_19.png` | `code/exhibits/06_rif_profiles.R` |
| Figure 20 | `output/figures/figure_20.png` | `code/exhibits/09_exceedance.R` |
| Table A1 | `output/tables/table_a1.csv` | `code/exhibits/02_sample_tables.R` |
| Figure A1 | `output/figures/figure_a1.png` | `code/exhibits/03_sample_figures.R` |
| Figure A2 | `output/figures/figure_a2.png` | `code/exhibits/03_sample_figures.R` |
| Figure A3 | `output/figures/figure_a3.png` | `code/exhibits/03_sample_figures.R` |
| Figure B1 (panel 1) | `output/figures/figure_b1_1.png` | `code/exhibits/04_weather_figures.R` |
| Figure B1 (panel 2) | `output/figures/figure_b1_2.png` | `code/exhibits/04_weather_figures.R` |
| Figure B1 (panel 3) | `output/figures/figure_b1_3.png` | `code/exhibits/04_weather_figures.R` |
| Figure B1 (panel 4) | `output/figures/figure_b1_4.png` | `code/exhibits/04_weather_figures.R` |
| Figure B2 (panel 1) | `output/figures/figure_b2_1.png` | `code/exhibits/04_weather_figures.R` |
| Figure B2 (panel 2) | `output/figures/figure_b2_2.png` | `code/exhibits/04_weather_figures.R` |
| Figure C1 | `output/figures/figure_c1.png` | `code/exhibits/05_coefficients.R` |
| Figure C2 | `output/figures/figure_c2.png` | `code/exhibits/05_coefficients.R` |
| Figure C3 | `output/figures/figure_c3.png` | `code/exhibits/05_coefficients.R` |
| Figure C4 | `output/figures/figure_c4.png` | `code/exhibits/05_coefficients.R` |
| Figure C5 (panel 1) | `output/figures/figure_c5_1.png` | `code/exhibits/07_regional_sims.R` |
| Figure C5 (panel 2) | `output/figures/figure_c5_2.png` | `code/exhibits/07_regional_sims.R` |
| Figure C6 | `output/figures/figure_c6.png` | `code/exhibits/06_rif_profiles.R` |
| Figure C7 | `output/figures/figure_c7.png` | `code/exhibits/06_rif_profiles.R` |
| Figure C8 | `output/figures/figure_c8.png` | `code/exhibits/06_rif_profiles.R` |
| Table F1 | `output/tables/table_f1.csv` | `code/exhibits/02_sample_tables.R` |
| Figure F1 | `output/figures/figure_f1.png` | `code/exhibits/02_sample_tables.R` |
| In-text numbers | `output/tables/intext_numbers.csv` | `code/exhibits/10_intext_numbers.R` |

`output/tables/intext_numbers.csv` contains 37 in-scope rows with report location, value, source table and filter. 

---

## Requirements

### Software

- **R version 4.5.3 (2026-03-11)**, https://cran.r-project.org/
  - Platform: Windows x64 (ucrt build), the full-run reference. macOS and Linux should work but are not tested for this run.
  - All package versions are managed by `renv` (`renv.lock`); `main.R` runs `renv::restore()`.
- **wiseapp 0.5.1** (WISE-APP, https://github.com/worldbank/wise-app), commit **1ccae37** (branch `dev`). Bundled as a source tarball in `renv/cellar/` and installed by `renv::restore()`, so no GitHub access is needed. On a first run the restore builds wiseapp from this tarball (about 1.5 minutes on the reference machine); later restores skip the build. It has C++ code, so a compiler toolchain is required: Xcode command line tools (`xcode-select --install`) on macOS, Rtools on Windows, `build-essential` on Linux.
- **duckdb 2.0.0** (`wiseapp` requires 2.0.0 or later). For the full run, DuckDB installs its `h3` extension from the community repository on first use: **internet is needed on the first full run**. On networks where HTTPS to `extensions.duckdb.org` fails, the HTTP route to `community-extensions.duckdb.org` worked on the reference machine.
- Key R packages for the exhibits: `dplyr`, `tidyr`, `tibble`, `stringr`, `forcats`, `ggplot2`, `ggrepel`, `scales`, `sf`, `arrow`, `jsonlite`, `cli`, `ragg`, `systemfonts`. Key packages for the full run: `wiseapp`, `targets`, `crew`, `yaml`, `arrow`, `digest`.

### Operating System

- Full run reference: Windows 11 Enterprise, build 26200 (x64). Tier 2 was run on the same machine.

### Runtime

Reference machine: Windows 11 Enterprise (build 26200), 2 x Intel Xeon Platinum 8562Y+ (32 cores, 32 logical processors), 64 GB RAM, R 4.5.3. The full run used one data worker and 4 simulation workers for `descriptives`, `models` and `regional`, and one simulation worker for `cases`.

| Step | Runtime (Windows, 32 cores, 64 GB memory) |
|---|---|
| Tier 2: exhibits from `results/` | about 2 min (110 s measured for `main.R` on local disk with the environment already installed) |
| Tier 1 `descriptives` (504 runs) | 3 h 48 min |
| Tier 1 `models` (651 fits) | 5 h 49 min |
| Tier 1 `regional` (66 runs) | 1 h 20 min |
| Tier 1 `cases` (MWI, BRA) | 1 h 08 min |
| Tier 1 exhibits and checks | about 2 min |
| **Tier 1 total** | ~ 12 h |

### Memory and Storage

- Full run: measured peak R memory (from R's own accounting, `provenance.parquet`) was 14.9 GB for the Brazil simulation and 18.1 GB for the Brazil cash-transfer policy. Keep the configured worker counts unless memory requirements have been assessed.
- Disk: `results/` is about 524 MB, including `SHA256SUMS`; that checksum file lists 1,571 result files. The input data archive is about 1.0 GB. The full run leaves `_targets/` at about 5.08 GB. Close other programs during the full run. Keep at least 10 GB of free disk.


---

## Code Description

### `main.R`

One-click run. Sets `root` and the switch `RUN_BATCH`, restores the environment, optionally runs the batch projects, verifies `results/SHA256SUMS`, then sources the exhibit scripts in order.

### `batch/` - estimation and simulation (WISE-APP batch pipeline)

| File | Purpose |
|---|---|
| `_targets.R` | Shared `targets` pipeline: `wiseapp::wise_targets()` on the spec of the project selected with `TAR_PROJECT`; writes `results/<project>/` |
| `descriptives/spec.yaml` | 21 countries; survey and weather statistics, 504 runs (Table A1, Table F1, Figures 2, A1 to A3, B1, B2, F1) |
| `models/spec.yaml` | 21 countries; 651 runs specifying linear and RIF models without simulation (Figures 6 to 9, C1 to C4, C6 to C8) |
| `regional/spec.yaml` | 11 West African countries; RIF model, SSP3-7.0 simulation, four policies (Figures 10 to 12, 14, 15, 18, C5, 13) |
| `cases/spec.yaml` | Case studies MWI (secondary education) and BRA (cash transfer, 1-3 month reference period) with the policy simulations (Figures 16, 17, 19, 20, Annex F). The Senegal case (Figures 12, 13) is part of `regional` |
| `../_targets.yaml` | Registers the four projects and their `_targets/<project>` stores |

Analysis settings shared by all projects: unit `hh`, outcome `welfare` (2021 PPP USD per day), fixed effects `year` + `loc_id_panel`, Lasso covariate selection, `seed: 123`, five equal-frequency weather bins unless stated, standard errors clustered at `loc_id_panel`.

### `code/exhibits/` - exhibit scripts (read `results/`, write `output/`)

| File | Exhibits |
|---|---|
| `01_map.R` | Figure 2 |
| `02_sample_tables.R` | Table A1, Table F1, Figure F1 |
| `03_sample_figures.R` | Figures A1, A2, A3 |
| `04_weather_figures.R` | Figures B1, B2 |
| `05_coefficients.R` | Figures 6, 7, C1 to C4 |
| `06_rif_profiles.R` | Figures 8, 9, 12, 16, 19, C6 to C8 |
| `07_regional_sims.R` | Figures 10, 11, 14, 15, 18, C5 |
| `08_decomposition.R` | Figures 13, 17 |
| `09_exceedance.R` | Figure 20 |
| `10_intext_numbers.R` | Every analysis number quoted in the text |

### `code/functions/` - shared helpers

| File | Purpose |
|---|---|
| `read_results.R` | Reads the batch tables; `check_batch()` reports batch failures |
| `theme_r2r.R` | One ggplot2 theme, colours and figure sizes for all figures |
| `coef_helpers.R` | Weather coefficient extraction for Figures 6, 7, C1 to C4 |
| `profile_helpers.R` | RIF profile and group-effect helpers (Figures 8, 9, 12, 16, 19, C6 to C8) |
| `policy_helpers.R` | Return-period rules and policy effects relative to the historical baseline |
| `decomposition_helpers.R` | Decile decomposition and 1-in-20 year selection |
| `country_names.R` | Country code to name lookup |

`code/exhibit_map.csv` maps content keys to report labels. `code/intext_numbers.csv` holds the report location and text of each in-text number.

---

## Folder Structure

```
risk-to-resilience/
├── main.R                    # run this to replicate all results
├── README.md
├── LICENSE
├── renv.lock, .Rprofile, .renvignore, renv/
│   └── cellar/               # bundled wiseapp source tarball
├── _targets.yaml             # the four batch projects
├── batch/                    # specs of the batch projects and shared pipeline
│   ├── _targets.R
│   ├── descriptives/spec.yaml
│   ├── models/spec.yaml
│   ├── regional/spec.yaml
│   └── cases/spec.yaml
├── code/
│   ├── exhibit_map.csv
│   ├── intext_numbers.csv
│   ├── functions/            # theme, readers, helpers
│   └── exhibits/             # one script per exhibit group
├── data/
│   ├── README.md             # layout and checksums of the WISE-APP data folder
│   └── boundaries/           # public World Bank boundaries for Figure 2
├── results/                  # batch aggregate tables (published) with SHA256SUMS
│   ├── descriptives/
│   ├── models/
│   ├── regional/
│   └── cases/
└── output/
    ├── figures/              # figure_<number>.png, e.g. figure_6_1.png
    ├── figure_data/          # plotted values of each figure
    └── tables/               # table_a1.csv, table_f1.csv, intext_numbers.csv
```

Each `results/<project>/` folder holds `tables/` (parquet, partitioned by country), `runs.parquet` (one row per run with its axis labels), `provenance.parquet`, `failures.parquet` and `manifest.json` (R, wiseapp and duckdb versions, SHA-256 of `renv.lock` and of every survey file used, run counts, failures).
