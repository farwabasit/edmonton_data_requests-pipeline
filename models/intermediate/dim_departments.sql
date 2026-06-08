{{
    config(
        materialized='table',
        schema='intermediate'
    )
}}

with all_departments as (
    select distinct
        department,
        count(*) as total_requests
    from {{ ref('stg_requests') }}
    where department is not null
    group by department
)

select 
    row_number() over (order by department) as department_key,
    department,
    total_requests,
    current_timestamp() as created_at
from all_departments