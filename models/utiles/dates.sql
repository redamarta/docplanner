with generated_date as (
{{ dbt_utils.date_spine( 
        datepart= "day",
        start_date="'2015-01-01'::date",
        end_date="add_months(current_date, 6)"
    )
    }}
)

select 
    date_day::date as date_day
    , date_trunc('month', date_day::date) as year_month
    , weekofyear(date_day) as week_of_year
    , case 
        when count(*) over (partition by year_month, week_of_year) = 7 
        then 'full_week'
        else 'partial_week'
    end as week_status
END AS weekly_completion_in_month
from generated_date