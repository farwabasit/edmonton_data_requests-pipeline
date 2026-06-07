{{
    config(
        materialized='table',
        schema='gold'
    )
}}

SELECT 
    department,
    COUNT(*) as total_requests,
    COUNT(DISTINCT status) as status_types,
    AVG(DATEDIFF('day', request_creation_date, status_date)) as avg_days_to_resolution,
    MIN(request_creation_date) as oldest_request,
    MAX(request_creation_date) as newest_request
FROM {{ ref('stg_requests') }}
WHERE status_date IS NOT NULL
GROUP BY department
HAVING COUNT(*) > 5
ORDER BY total_requests DESC