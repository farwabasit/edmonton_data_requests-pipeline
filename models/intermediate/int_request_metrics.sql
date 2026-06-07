{{
    config(
        materialized='table',
        schema='intermediate'
    )
}}

with base as (
    select * from {{ ref('stg_requests') }}
)

select 
    request_number,
    department,
    status,
    {{ categorize_status('status') }} as status_category,
    request_creation_date,
    status_date,
    datediff('day', request_creation_date, status_date) as days_to_resolution,
    case 
        when request_details is not null and length(request_details) > 10 then 'Detailed'
        when request_description is not null then 'Has Description'
        else 'Minimal'
    end as request_completeness,
    ingested_at
from base