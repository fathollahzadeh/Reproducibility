SELECT
    AVG(
        CAST(
            CAST(realestate11.price AS BIGINT) AS DOUBLE PRECISION
        )
    ) AS avgpriceok,
    CAST(
        EXTRACT(
            YEAR
            FROM
                realestate11.date_of_transfer
        ) AS BIGINT
    ) AS yrdateoftransferok
FROM
    realestate11
WHERE
    (
        (
            CAST(
                EXTRACT(
                    YEAR
                    FROM
                        realestate11.date_of_transfer
                ) AS BIGINT
            ) IN (
                2005,
                2006,
                2007,
                2008,
                2009,
                2010,
                2011,
                2012,
                2013,
                2014
            )
        )
        AND (
            CAST(realestate11.date_of_transfer as DATE) >= cast('2005-01-01' as DATE)
        )
        AND (
            CAST(realestate11.date_of_transfer as DATE) <= cast('2015-03-31' as DATE)
        )
    )
GROUP BY
    yrdateoftransferok;