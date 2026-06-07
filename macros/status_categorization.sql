{% macro categorize_status(status) %}
    case 
        when {{ status }} in ('Completed', 'Published', 'Done') then 'Resolved'
        when {{ status }} in ('Declined', 'Rejected', 'Cancelled') then 'Closed - Not Resolved'
        when {{ status }} in ('New', 'Under Review', 'In Progress', 'On Hold') then 'Open'
        else 'Unknown'
    end
{% endmacro %}