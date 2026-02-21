SELECT
    realestate23.calculation222787466264023043 AS calculation222787466264023043,
    realestate23.calculation342484700263473152 AS calculation342484700263473152,
    realestate23.dateoftransfer AS dateoftransfer,
    realestate23.street AS street,
    AVG(CAST(realestate23.latitude AS DOUBLE PRECISION)) AS avglatitudeok,
    AVG(CAST(realestate23.longitude AS DOUBLE PRECISION)) AS avglongitudeok,
    AVG(
        CAST(
            CAST(realestate23.price AS BIGINT) AS DOUBLE PRECISION
        )
    ) AS avgpriceok,
    MIN(realestate23.dateoftransfer) AS maxdateoftransferok,
    realestate23.town_city_url_string__copy_ AS town_city_url_string__copy_
FROM
    realestate23
WHERE
    (
        (realestate23.street ILIKE 'THE BISHOPS AVENUE')
        AND (
            realestate23.dateoftransfer >= cast('1996-01-01' as DATE)
        )
        AND (
            realestate23.dateoftransfer < cast('2019-01-01' as DATE)
        )
        AND (realestate23.county = 'GREATER LONDON')
        AND (realestate23.postcodedistrict = 'N2')
    )
GROUP BY
    realestate23.calculation222787466264023043,
    realestate23.calculation342484700263473152,
    realestate23.dateoftransfer,
    realestate23.street,
    realestate23.town_city_url_string__copy_;