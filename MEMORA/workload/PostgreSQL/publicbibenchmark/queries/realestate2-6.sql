SELECT
    realestate25.calculation222787466264023043 AS calculation222787466264023043,
    realestate25.street AS street,
    AVG(
        CAST(
            CAST(realestate25.price AS BIGINT) AS DOUBLE PRECISION
        )
    ) AS avgpriceok,
    SUM(1) AS cntdateoftransferok,
    CAST(MAX(realestate25.price) AS BIGINT) AS maxpriceok
FROM
    realestate25
WHERE
    (
       (realestate25.street ILIKE 'THE BISHOPS AVENUE')
        AND (realestate25.county = 'GREATER LONDON')
        AND (
            realestate25.dateoftransfer >= cast('1996-01-01' as DATE)
        )
        AND (
            realestate25.dateoftransfer < cast('2019-01-01' as DATE)
        )
        AND (realestate25.postcodedistrict = 'N2')
    )
GROUP BY
    realestate25.calculation222787466264023043,
    realestate25.street;