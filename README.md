# Teradata Bronze-Silver-Gold Pipeline (Boston Housing CSV)

This project provides:
- TPT load script for Bronze layer.
- BTEQ transform scripts for Silver and Gold layers.
- Control-table based dependency checks.
- Control-table based run-status updates.
- Retry policy: 3 attempts, 30-minute interval.
- Daily scheduling at 05:30 IST via cron.

## Folder layout

- `sql/00_control_tables.sql`: control table DDL and seed data.
- `sql/01_bronze_tables.sql`: Bronze table DDL.
- `sql/02_silver_tables.sql`: Silver table DDL.
- `sql/03_gold_tables.sql`: Gold table DDL.
- `tpt/load_boston_bronze.tpt`: CSV to Bronze load.
- `bteq/dependency_check_template.btq`: dependency validation using control tables.
- `bteq/job_status_template.btq`: run stats and latest status update.
- `bteq/30_silver_transform.btq`: Bronze to Silver transform.
- `bteq/40_gold_transform.btq`: Silver to Gold star-schema load.
- `scripts/setup_database.ps1`: creates metadata and layer tables.
- `scripts/run_pipeline.ps1`: orchestration with dependency check + retries.
- `scripts/register_cron_530_ist.sh`: schedules daily run in cron at 05:30 IST.
- `scripts/remove_cron_530_ist.sh`: removes the cron schedule.
- `config/env.ps1`: environment settings.

## Control table logic

`ETL_CTRL.pipeline_control`
- Stores per-job schedule, enable flag, retry settings, and latest run status.

`ETL_CTRL.pipeline_dependencies`
- Defines dependencies:
- `SILVER_BUILD_BOSTON` depends on `BRONZE_LOAD_BOSTON`
- `GOLD_BUILD_BOSTON` depends on `SILVER_BUILD_BOSTON`

`ETL_CTRL.pipeline_run_stats`
- Stores daily run status (`RUNNING`, `SUCCESS`, `FAILED`) and attempt number.

## Gold star schema

Gold layer uses a star schema for analytics:

- `TD_GOLD.dim_run`: run-level dimension (`run_key`, `run_id`, `run_date`).
- `TD_GOLD.dim_location`: location dimension (`location_key`, `chas`, `rad`).
- `TD_GOLD.fact_boston_housing_metrics`: fact table with measures by run and location.

Fact table grain:
- One row per `run_id + (chas, rad)` group.

## Configure

1. Put input file at `data/boston_housing.csv`.
2. Update credentials in `config/env.ps1`:
- `TD_TDPID`
- `TD_USER`
- `TD_PASS`

## Run once (manual)

```powershell
cd "c:\Users\LENOVO\Documents\Google ADK\bteq"
powershell -ExecutionPolicy Bypass -File .\scripts\setup_database.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_pipeline.ps1
```

## Schedule at 05:30 IST (cron)

```bash
cd "c:/Users/LENOVO/Documents/Google ADK/bteq"
bash ./scripts/register_cron_530_ist.sh
```

To remove the schedule:

```bash
bash ./scripts/remove_cron_530_ist.sh
```

Cron entry uses `CRON_TZ=Asia/Kolkata` so it runs at 05:30 IST.

## Retry behavior

Each job (`Bronze`, `Silver`, `Gold`) is executed with:
- Max retries: 3
- Retry interval: 30 minutes

If a job fails after 3 attempts, pipeline stops and status is recorded in `ETL_CTRL.pipeline_run_stats` and `ETL_CTRL.pipeline_control`.
