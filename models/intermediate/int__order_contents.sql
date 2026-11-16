with items as (

    select
        order_id,
        sku

    from {{ ref('stg__jaffle_shop__raw_items') }}

),

order_contents as (

    select
        order_id,
        count(*) as item_count,
        countif(sku = 'JAF-001') as jaf_001_qty,
        countif(sku = 'JAF-002') as jaf_002_qty,
        countif(sku = 'JAF-003') as jaf_003_qty,
        countif(sku = 'JAF-004') as jaf_004_qty,
        countif(sku = 'JAF-005') as jaf_005_qty,
        countif(sku = 'BEV-001') as bev_001_qty,
        countif(sku = 'BEV-002') as bev_002_qty,
        countif(sku = 'BEV-003') as bev_003_qty,
        countif(sku = 'BEV-004') as bev_004_qty,
        countif(sku = 'BEV-005') as bev_005_qty

    from items
    group by order_id

)

select * from order_contents
