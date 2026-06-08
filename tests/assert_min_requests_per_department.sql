-- Fail if any department in gold performance table 
-- has 5 or fewer requests (business rule: minimum sample size)
select *
from {{ ref('fct_dept_performance') }}
where total_requests <= 5