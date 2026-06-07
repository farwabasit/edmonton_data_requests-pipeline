{{
    config(
        materialized='view',
        schema='silver'
    )
}}

SELECT 
    raw_data:request_number::STRING as request_number,
    raw_data:request_description::STRING as request_description,
    raw_data:request_details::STRING as request_details,
    raw_data:request_creation_date::DATE as request_creation_date,
    raw_data:status::STRING as status,
    raw_data:status_date::DATE as status_date,
    raw_data:department::STRING as department,
    raw_data:dataset_published_date::DATE as dataset_published_date,
    ingested_at
FROM {{ source('bronze', 'edmonton_requests_raw') }}
WHERE raw_data:request_number IS NOT NULL