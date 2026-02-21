SELECT
    SUM(
        CAST(trainsuk22.number_of_records AS SIGNED)
    ) AS sumnumberofrecordsok
FROM
    trainsuk22
HAVING
    (COUNT(1) > 0);