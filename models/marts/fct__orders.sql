with orders as (

    select * from {{ ref('stg__jaffle_shop__raw_orders') }}

),

order_contents as (

    select * from {{ ref('int__order_contents') }}

),

customer_history as (

    select * from {{ ref('int__customer_history') }}

),

customers as (

    select
        customer_id,
        customer_name,
        visit_group,
        is_repeat_customer

    from {{ ref('dim__customers') }}

),

stores as (

    select
        store_id,
        store_name

    from {{ ref('stg__jaffle_shop__raw_stores') }}

)

select
    orders.order_id,
    orders.customer_id,
    customers.customer_name,
    orders.store_id,
    stores.store_name,
    orders.ordered_at,
    orders.order_date,
    customer_history.visit_number,
    customer_history.previous_ordered_at,
    customer_history.days_since_previous_order,
    customers.visit_group as customer_visit_group,
    customers.is_repeat_customer,
    {{ cents_to_dollars('orders.order_subtotal') }} as order_subtotal_dollars,
    {{ cents_to_dollars('orders.order_tax_paid') }} as order_tax_paid_dollars,
    {{ cents_to_dollars('orders.order_total') }} as order_total_dollars,
    coalesce(order_contents.item_count, 0) as item_count,
    coalesce(order_contents.jaf_001_qty, 0) as jaf_001_qty,
    coalesce(order_contents.jaf_002_qty, 0) as jaf_002_qty,
    coalesce(order_contents.jaf_003_qty, 0) as jaf_003_qty,
    coalesce(order_contents.jaf_004_qty, 0) as jaf_004_qty,
    coalesce(order_contents.jaf_005_qty, 0) as jaf_005_qty,
    coalesce(order_contents.bev_001_qty, 0) as bev_001_qty,
    coalesce(order_contents.bev_002_qty, 0) as bev_002_qty,
    coalesce(order_contents.bev_003_qty, 0) as bev_003_qty,
    coalesce(order_contents.bev_004_qty, 0) as bev_004_qty,
    coalesce(order_contents.bev_005_qty, 0) as bev_005_qty

from orders
left join order_contents
    on orders.order_id = order_contents.order_id
left join customer_history
    on orders.order_id = customer_history.order_id
left join customers
    on orders.customer_id = customers.customer_id
left join stores
    on orders.store_id = stores.store_id
