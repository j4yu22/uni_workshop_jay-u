with source_items as (

    select
        order_id,
        count(*) as item_count

    from {{ ref('stg__jaffle_shop__raw_items') }}
    group by order_id

)

select coalesce(orders.order_id, source_items.order_id) as order_id

from {{ ref('fct__orders') }} as orders
full outer join source_items
    on orders.order_id = source_items.order_id

where orders.order_id is null
    or coalesce(orders.item_count, -1) != coalesce(source_items.item_count, 0)
    or coalesce(orders.item_count, -1) != coalesce(
        orders.jaf_001_qty + orders.jaf_002_qty + orders.jaf_003_qty
        + orders.jaf_004_qty + orders.jaf_005_qty + orders.bev_001_qty
        + orders.bev_002_qty + orders.bev_003_qty + orders.bev_004_qty
        + orders.bev_005_qty, -2
    )
    or least(
        orders.jaf_001_qty, orders.jaf_002_qty, orders.jaf_003_qty,
        orders.jaf_004_qty, orders.jaf_005_qty, orders.bev_001_qty,
        orders.bev_002_qty, orders.bev_003_qty, orders.bev_004_qty,
        orders.bev_005_qty
    ) < 0
