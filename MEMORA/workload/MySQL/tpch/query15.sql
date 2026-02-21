
DROP VIEW IF EXISTS revenue15;

create view revenue15 (supplier_no, total_revenue) as
select
    l_suppkey,
    sum(l_extendedprice * (1 - l_discount))
from
    lineitem
where
    l_shipdate >= '1996-01-01'
    and l_shipdate < DATE_ADD('1996-01-01', INTERVAL 3 MONTH)
group by
    l_suppkey;

select
    s_suppkey,
    s_name,
    s_address,
    s_phone,
    total_revenue
from
    supplier,
    revenue15
where
    s_suppkey = supplier_no
    and total_revenue = (
        select
            max(total_revenue)
        from
            revenue15
    )
order by
    s_suppkey;

drop view revenue15;