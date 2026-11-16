select customer_id

from {{ ref('dim__customers') }}

where total_visits is null
    or total_visits < 0
    or is_repeat_customer is null
    or is_repeat_customer != (total_visits >= 3)
    or visit_group is null
    or (total_visits = 0 and visit_group != '0')
    or (total_visits = 1 and visit_group != '1')
    or (total_visits = 2 and visit_group != '2')
    or (total_visits >= 3 and visit_group != '3+')
    or (total_visits < 2 and (
        second_ordered_at is not null
        or days_to_second_order is not null
        or avg_days_between_visits is not null
    ))
    or (total_visits >= 2 and (
        second_ordered_at is null
        or days_to_second_order is null
        or avg_days_between_visits is null
        or days_to_second_order < 0
        or avg_days_between_visits < 0
    ))
    or (total_visits = 0 and (
        first_ordered_at is not null
        or latest_ordered_at is not null
        or avg_order_total_dollars is not null
        or total_spend_dollars != 0
    ))
