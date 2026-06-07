{{
    config(
        materialized='table',
        schema='gold'
    )
}}

select 
    department,
    status_category,
    status,
    count(*) as request_count,
    count(distinct request_number) as unique_requests,
    avg(days_to_resolution) as avg_days_to_resolution,
    min(request_creation_date) as first_request_date,
    max(request_creation_date) as last_request_date
from {{ ref('int_request_metrics') }}
group by department, status_category, status
order by request_count desc