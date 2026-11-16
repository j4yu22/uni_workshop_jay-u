with source_items as (

    select
        order_id,
        sku,
        count(*) as quantity

    from {{ source('jaffle_shop', 'raw_items') }}
    group by order_id, sku

),

actual_quantities as (

    select order_id, sku, quantity

    from {{ ref('fct__orders') }}
    unpivot include nulls (
        quantity for sku in (
            jaf_001_qty as 'JAF-001',
            jaf_002_qty as 'JAF-002',
            jaf_003_qty as 'JAF-003',
            jaf_004_qty as 'JAF-004',
            jaf_005_qty as 'JAF-005',
            bev_001_qty as 'BEV-001',
            bev_002_qty as 'BEV-002',
            bev_003_qty as 'BEV-003',
            bev_004_qty as 'BEV-004',
            bev_005_qty as 'BEV-005'
        )
    )

)

select
    coalesce(actual_quantities.order_id, source_items.order_id) as order_id,
    coalesce(actual_quantities.sku, source_items.sku) as sku,
    actual_quantities.quantity as actual_quantity,
    coalesce(source_items.quantity, 0) as expected_quantity

from source_items
full outer join actual_quantities
    on source_items.order_id = actual_quantities.order_id
    and source_items.sku = actual_quantities.sku

where actual_quantities.order_id is null
    or actual_quantities.quantity is distinct from coalesce(source_items.quantity, 0)
