with source_summary as (

    select
        customer as customer_id,
        count(*) as total_visits,
        min(timestamp(ordered_at)) as first_ordered_at,
        array_agg(timestamp(ordered_at) order by timestamp(ordered_at), id limit 2)[safe_offset(1)]
            as second_ordered_at,
        max(timestamp(ordered_at)) as latest_ordered_at,
        sum(cast(order_total as numeric)) / 100 as total_spend_dollars,
        round(avg(cast(order_total as numeric)) / 100, 2) as avg_order_total_dollars

    from {{ source('jaffle_shop', 'raw_orders') }}
    group by customer

),

expected_customers as (

    select
        customers.id as customer_id,
        customers.name as customer_name,
        coalesce(summary.total_visits, 0) as total_visits,
        summary.first_ordered_at,
        summary.second_ordered_at,
        summary.latest_ordered_at,
        timestamp_diff(summary.second_ordered_at, summary.first_ordered_at, second)
            / 86400.0 as days_to_second_order,
        safe_divide(
            timestamp_diff(summary.latest_ordered_at, summary.first_ordered_at, second)
                / 86400.0,
            summary.total_visits - 1
        ) as avg_days_between_visits,
        coalesce(summary.total_spend_dollars, 0) as total_spend_dollars,
        summary.avg_order_total_dollars

    from {{ source('jaffle_shop', 'raw_customers') }} as customers
    left join source_summary as summary
        on customers.id = summary.customer_id

)

select coalesce(expected.customer_id, customers.customer_id) as customer_id

from expected_customers as expected
full outer join {{ ref('dim__customers') }} as customers
    on expected.customer_id = customers.customer_id

where expected.customer_id is null
    or customers.customer_id is null
    or customers.customer_name is distinct from expected.customer_name
    or customers.total_visits is distinct from expected.total_visits
    or customers.first_ordered_at is distinct from expected.first_ordered_at
    or customers.second_ordered_at is distinct from expected.second_ordered_at
    or customers.latest_ordered_at is distinct from expected.latest_ordered_at
    or customers.total_spend_dollars is distinct from expected.total_spend_dollars
    or customers.avg_order_total_dollars is distinct from expected.avg_order_total_dollars
    or (customers.days_to_second_order is null) != (expected.days_to_second_order is null)
    or abs(customers.days_to_second_order - expected.days_to_second_order) > 0.000001
    or (customers.avg_days_between_visits is null) != (expected.avg_days_between_visits is null)
    or abs(customers.avg_days_between_visits - expected.avg_days_between_visits) > 0.000001
