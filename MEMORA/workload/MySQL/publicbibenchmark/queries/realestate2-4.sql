SELECT
    realestate23.postcodedistrict AS postcodedistrict
FROM
    realestate23
WHERE
    (
        (LOWER(realestate23.street) = 'the bishops avenue')
        AND (realestate23.county = 'GREATER LONDON')
        AND (
            realestate23.dateoftransfer >= cast('1996-01-01' as DATE)
        )
        AND (
            realestate23.dateoftransfer < cast('2019-01-01' as DATE)
        )
        AND (realestate23.propertytype <> 'O')
    )
GROUP BY
    realestate23.postcodedistrict;