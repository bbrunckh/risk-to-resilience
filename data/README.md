# WISE-APP data folder

The full run (tier 1 in the main README) reads the WISE-APP data folder, which is deposited in DDH as one restricted archive, `wiseapp_data_r2r.zip` (about 1.0 GB, 172 files). Unzip it into a new folder and point `WISEAPP_DATA_PATH` at that folder. Tier 2 does not need it.

The archive holds only the files this package reads. The source folder is larger: it also has 12 other countries, individual-level survey files (`ind`), and projections for other scenarios and countries.

The weather files are also cut to the months the batch pipeline reads: ERA5-Land and `cmip6_historical` from January 1989 (the pipeline uses the 1991-2020 reference period and survey dates from 2006, each less a lag of up to 12 months), and `cmip6_ssp370` up to December 2061 (the last future period in the specs ends in 2060). Rows are otherwise unchanged (same columns, types and values); the full-record files are in the source folder. `metadata/manifest.csv` describes the source files, so its sizes, row counts and checksums for weather files do not match this archive; use `SHA256SUMS`.

## Layout

| Path | Files | Content |
|---|---|---|
| `microdata/hh/<CODE>/<CODE>_<year>_<survey>_GMD_hh.parquet` | 60 | Household survey files, 21 countries, 60 waves (restricted) |
| `microdata/h3/<CODE>/<CODE>_<year>_<survey>_GMD_h3.parquet` | 60 | H3 location lookup with GHS-POP 2020 weights, built from the survey geocodes (restricted) |
| `hazard/weather/historical/<CODE>/<CODE>_era5land.parquet` | 21 | Monthly ERA5-Land weather by H3 cell |
| `hazard/weather/projections/<CODE>/<CODE>_cmip6_historical.parquet` | 13 | CMIP6 historical run by H3 cell, simulated countries only |
| `hazard/weather/projections/<CODE>/<CODE>_cmip6_ssp370.parquet` | 13 | CMIP6 SSP3-7.0 projections by H3 cell, simulated countries only |
| `metadata/` | 5 | `survey_list.csv`, `variable_list.csv`, `cpi_ppp.csv`, `manifest.csv`, `release.json` |

The 21 countries are BEN, BFA, BRA, CIV, COL, GMB, GNB, GTM, IND, IRN, LKA, MLI, MRT, MWI, NER, SEN, TCD, TGO, TJK, VNM and ZMB. The 13 simulated countries are the 11 of `regional` (BEN, BFA, CIV, GMB, GNB, MLI, MRT, NER, SEN, TCD, TGO) plus MWI and BRA (`cases`).

## Provenance

Built by `worldbank/wise-app-data` at commit `9b5bab2` (data version 2026.10.23, see `metadata/release.json`). The archive `wise-app-data_9b5bab2.zip` deposited with the data is the repository at that commit. `metadata/manifest.csv` and `release.json` describe the full source folder, which is larger than this archive.

## Checksums

`SHA256SUMS` in this folder lists the SHA-256 of every file in the archive (paths relative to the unzipped folder). To check on macOS or Linux, run `shasum -a 256 -c` on it from the unzipped folder, after copying `SHA256SUMS` there. The batch pipeline also records the checksums of the survey files it used in `results/<project>/manifest.json`.
