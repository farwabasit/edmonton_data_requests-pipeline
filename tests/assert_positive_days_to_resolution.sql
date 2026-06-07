-- Fail if any resolved request has negative days to resolution
select *
from {{ ref('int_request_metrics') }}
where status_category = 'Resolved'
  and days_to_resolution < 0