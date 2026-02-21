SELECT
    medicare11.specialtydesc AS specialtydesc,
    AVG(
        CAST(
            medicare11.calculation3170826185505725 AS DOUBLE PRECISION
        )
    ) AS avgcalculation3170826185505725ok
FROM
    medicare11
GROUP BY
    medicare11.specialtydesc
ORDER BY
    avgcalculation3170826185505725ok DESC
LIMIT
    15;