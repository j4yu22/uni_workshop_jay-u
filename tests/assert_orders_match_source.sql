with source_orders as (

    select * from {{ source('jaffle_shop', 'raw_orders') }}

),

customer_visits as (

    select
        customer as customer_id,
        count(*) as total_visits

    from source_orders
    group by customer

)

select coalesce(source_orders.id, orders.order_id) as order_id

from source_orders
full outer join {{ ref('fct__orders') }} as orders
    on source_orders.id = orders.order_id
left join customer_visits
    on source_orders.customer = customer_visits.customer_id

where source_orders.id is null
    or orders.order_id is null
    or orders.customer_id is distinct from source_orders.customer
    or orders.store_id is distinct from source_orders.store_id
    or orders.ordered_at is distinct from timestamp(source_orders.ordered_at)
    or orders.order_date is distinct from date(timestamp(source_orders.ordered_at))
    or orders.order_subtotal_dollars is distinct from
        cast(source_orders.subtotal as numeric) / 100
    or orders.order_tax_paid_dollars is distinct from
        cast(source_orders.tax_paid as numeric) / 100
    or orders.order_total_dollars is distinct from
        cast(source_orders.order_total as numeric) / 100
    or orders.is_repeat_customer is distinct from (customer_visits.total_visits >= 3)
    or orders.customer_visit_group is distinct from case
        when customer_visits.total_visits >= 3 then '3+'
        else cast(customer_visits.total_visits as string)
    end
