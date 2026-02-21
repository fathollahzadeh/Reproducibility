SELECT
    realestate26.street AS street,
    AVG(
        CAST(
            CAST(realestate26.price AS BIGINT) AS DOUBLE PRECISION
        )
    ) AS avgpriceok,
    CAST(
        EXTRACT(
            MONTH
            FROM
                realestate26.dateoftransfer
        ) AS BIGINT
    ) AS mndateoftransferok
FROM
    realestate26
WHERE
    (
        (realestate26.street ILIKE 'THE BISHOPS AVENUE') 
        AND (realestate26.county = 'GREATER LONDON')
        AND (
            realestate26.dateoftransfer >= cast('1996-01-01' as DATE)
        )
        AND (
            realestate26.dateoftransfer < cast('2019-01-01' as DATE)
        )
        AND (realestate26.postcodedistrict = 'N2')
    )
GROUP BY
    realestate26.street,
    mndateoftransferok;