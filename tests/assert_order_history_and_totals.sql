with customer_sequences as (

    select
        customer_id,
        count(*) as order_count,
        min(visit_number) as first_visit,
        max(visit_number) as last_visit,
        count(distinct visit_number) as unique_visits

    from {{ ref('fct__orders') }}
    group by customer_id

)

select orders.order_id

from {{ ref('fct__orders') }} as orders
left join customer_sequences
    on orders.customer_id = customer_sequences.customer_id
left join {{ ref('fct__orders') }} as previous_order
    on orders.customer_id = previous_order.customer_id
    and orders.visit_number = previous_order.visit_number + 1

where orders.ordered_at is null
    or orders.visit_number is null
    or customer_sequences.first_visit != 1
    or customer_sequences.last_visit != customer_sequences.order_count
    or customer_sequences.unique_visits != customer_sequences.order_count
    or (orders.visit_number = 1 and (
        orders.previous_ordered_at is not null
        or orders.days_since_previous_order is not null
    ))
    or (orders.visit_number > 1 and (
        previous_order.order_id is null
        or orders.previous_ordered_at is null
        or orders.previous_ordered_at is distinct from previous_order.ordered_at
        or (orders.ordered_at = previous_order.ordered_at
            and orders.order_id < previous_order.order_id)
        or abs(orders.days_since_previous_order
            - timestamp_diff(orders.ordered_at, previous_order.ordered_at, second) / 86400.0
        ) > 0.000001
        or orders.days_since_previous_order is null
        or orders.previous_ordered_at > orders.ordered_at
        or orders.days_since_previous_order < 0
    ))
    or orders.order_subtotal_dollars is null
    or orders.order_tax_paid_dollars is null
    or orders.order_total_dollars is null
    or orders.order_subtotal_dollars + orders.order_tax_paid_dollars
        != orders.order_total_dollars
