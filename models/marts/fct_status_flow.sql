{{
    config(
        materialized='table',
        schema='gold'
    )
}}

SELECT 
    status,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status_date IS NOT NULL THEN 1 END) as with_status_date,
    MIN(status_date) as earliest_status_date,
    MAX(status_date) as latest_status_date
FROM {{ ref('stg_requests') }}
GROUP BY status
ORDER BY total_requests DESC