# Edmonton Data Requests Pipeline

A dbt-based analytics pipeline that transforms Edmonton's [Open Data API](https://data.edmonton.ca/) citizen dataset request records into clean, query-ready tables for reporting in Power BI.

Raw request data is ingested from the API by Azure Data Factory every 6 hours into a Snowflake **bronze** schema. This dbt project takes it from there, cleaning and modeling it through a medallion (bronze → silver → gold) architecture.

## Architecture

```
Edmonton Open Data API
        │
        ▼
Azure Data Factory  (ingestion, every 6 hours)
        │
        ▼
Snowflake: bronze.edmonton_requests_raw   (raw JSON)
        │
        ▼
        dbt
        │
   ┌────┴────┬─────────────┐
   ▼         ▼             ▼
 silver   intermediate    gold
(staging)  (metrics)    (marts, for Power BI)
```

| Layer | Schema | Materialization | Purpose |
|---|---|---|---|
| Bronze | `bronze` | source table | Raw JSON loaded by ADF |
| Silver | `silver` | view | Parsed, typed, deduplicated requests |
| Intermediate | `intermediate` | table | Derived metrics (resolution time, status grouping) |
| Gold | `gold` | table | Aggregated marts consumed by Power BI |

## Project structure

```
models/
├── staging/
│   ├── sources.yml          # bronze source definition + freshness checks
│   ├── stg_requests.sql     # parses raw JSON, dedupes by request_number
│   └── schema.yml
├── intermediate/
│   ├── dim_departments.sql      # one row per department, with request volume
│   ├── int_request_metrics.sql  # days_to_resolution, status_category, completeness
│   └── schema.yml
└── marts/
    ├── fct_requests_by_dept.sql   # request counts by department + status
    ├── fct_dept_performance.sql   # avg resolution time per department
    ├── fct_status_flow.sql        # request counts by status
    └── schema.yml

macros/
├── generate_schema_name.sql   # controls custom schema naming (silver/intermediate/gold)
└── status_categorization.sql  # categorize_status(): maps raw statuses to Resolved / Closed - Not Resolved / Open / Unknown

tests/
├── assert_min_requests_per_department.sql   # fails if a dept in the gold table has ≤5 requests
└── assert_positive_days_to_resolution.sql   # fails if a resolved request has negative resolution time

analyses/   seeds/   snapshots/   # currently empty, reserved for future use
```

## What each model does

**`stg_requests`** — Parses the raw JSON in `bronze.edmonton_requests_raw` into typed columns (`request_number`, `status`, `department`, `request_creation_date`, `status_date`, etc.), then deduplicates so only the most recently ingested version of each `request_number` is kept.

**`dim_departments`** — Distinct list of departments with a surrogate key and total request volume.

**`int_request_metrics`** — Adds derived fields per request: `days_to_resolution` (days between creation and status date), `status_category` (via the `categorize_status` macro), and a `request_completeness` flag based on how much detail was provided.

**`fct_requests_by_dept`** — Request counts and average resolution time, grouped by department, status category, and status.

**`fct_dept_performance`** — Department-level rollup: total requests, distinct status types, average/min/max dates. Only includes departments with more than 5 requests.

**`fct_status_flow`** — Request counts grouped by status, with earliest/latest status dates.

## Data quality checks

Beyond the built-in dbt tests (`unique`, `not_null`, `accepted_values`) declared in each `schema.yml`, this project has two custom singular tests:

- **`assert_min_requests_per_department`** — enforces a minimum sample size of 5+ requests per department in the gold performance table.
- **`assert_positive_days_to_resolution`** — catches data errors where a resolved request's `status_date` falls before its `request_creation_date`.

Source freshness is also checked on `bronze.edmonton_requests_raw`: a warning after 12 hours without new data, an error after 25 hours.

## Getting started

1. **Install dbt** with the Snowflake adapter:
   ```bash
   pip install dbt-snowflake
   ```
2. **Configure your Snowflake connection** in `~/.dbt/profiles.yml` under the `default` profile (matching the `profile: 'default'` set in `dbt_project.yml`).
3. **Run the models:**
   ```bash
   dbt run
   ```
4. **Run the tests:**
   ```bash
   dbt test
   ```
5. **Check source freshness:**
   ```bash
   dbt source freshness
   ```

## Tech stack

- **Azure Data Factory** — scheduled ingestion from the Edmonton Open Data API
- **Snowflake** — warehouse, bronze/silver/gold schemas
- **dbt** — transformation, testing, documentation
- **Power BI** — reporting on the gold-layer marts
