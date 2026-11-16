with orders as (

    select
        order_id,
        customer_id,
        ordered_at

    from {{ ref('stg__jaffle_shop__raw_orders') }}

),

order_history as (

    select
        order_id,
        customer_id,
        ordered_at,
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as visit_number,
        lag(ordered_at) over (
            partition by customer_id
            order by ordered_at, order_id
        ) as previous_ordered_at

    from orders

)

select
    order_id,
    customer_id,
    ordered_at,
    visit_number,
    previous_ordered_at,
    timestamp_diff(ordered_at, previous_ordered_at, second) / 86400.0
        as days_since_previous_order

from order_history
