with customers as (

    select
        customer_id,
        customer_name

    from {{ ref('stg__jaffle_shop__customers') }}

),

visit_summary as (

    select
        customer_id,
        count(*) as total_visits,
        min(ordered_at) as first_ordered_at,
        max(case when visit_number = 2 then ordered_at end) as second_ordered_at,
        max(ordered_at) as latest_ordered_at,
        max(case when visit_number = 2 then days_since_previous_order end)
            as days_to_second_order,
        avg(days_since_previous_order) as avg_days_between_visits

    from {{ ref('int__customer_history') }}
    group by customer_id

),

spending_summary as (

    select
        customer_id,
        {{ cents_to_dollars('sum(order_total)') }} as total_spend_dollars,
        {{ cents_to_dollars('avg(cast(order_total as numeric))') }}
            as avg_order_total_dollars

    from {{ ref('stg__jaffle_shop__raw_orders') }}
    group by customer_id

)

select
    customers.customer_id,
    customers.customer_name,
    coalesce(visit_summary.total_visits, 0) as total_visits,
    case
        when coalesce(visit_summary.total_visits, 0) = 0 then '0'
        when visit_summary.total_visits = 1 then '1'
        when visit_summary.total_visits = 2 then '2'
        else '3+'
    end as visit_group,
    coalesce(visit_summary.total_visits, 0) >= 3 as is_repeat_customer,
    visit_summary.first_ordered_at,
    visit_summary.second_ordered_at,
    visit_summary.latest_ordered_at,
    visit_summary.days_to_second_order,
    visit_summary.avg_days_between_visits,
    coalesce(spending_summary.total_spend_dollars, 0) as total_spend_dollars,
    spending_summary.avg_order_total_dollars

from customers
left join visit_summary
    on customers.customer_id = visit_summary.customer_id
left join spending_summary
    on customers.customer_id = spending_summary.customer_id
