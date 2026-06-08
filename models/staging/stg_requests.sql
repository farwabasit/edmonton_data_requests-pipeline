{{
    config(
        materialized='view',
        schema='silver'
    )
}}

WITH deduplicated AS (
    SELECT
        raw_data:request_number::STRING as request_number,
        raw_data:request_description::STRING as request_description,
        raw_data:request_details::STRING as request_details,
        raw_data:request_creation_date::DATE as request_creation_date,
        raw_data:status::STRING as status,
        raw_data:status_date::DATE as status_date,
        raw_data:department::STRING as department,
        raw_data:dataset_published_date::DATE as dataset_published_date,
        ingested_at,
        ROW_NUMBER() OVER (
            PARTITION BY raw_data:request_number::STRING 
            ORDER BY ingested_at DESC
        ) as row_num
    FROM {{ source('bronze', 'edmonton_requests_raw') }}
    WHERE raw_data:request_number IS NOT NULL
)

SELECT
    request_number,
    request_description,
    request_details,
    request_creation_date,
    status,
    status_date,
    department,
    dataset_published_date,
    ingested_at
FROM deduplicated
WHERE row_num = 1