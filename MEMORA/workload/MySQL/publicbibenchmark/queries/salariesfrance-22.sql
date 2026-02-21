SELECT
    salariesfrance9.ze2010lib AS ze2010lib,
    AVG(
        CAST(
            salariesfrance9.latitude AS DOUBLE PRECISION
        )
    ) AS avglatitudeok,
    AVG(
        CAST(
            salariesfrance9.longitude AS DOUBLE PRECISION
        )
    ) AS avglongitudeok,
    SUM(salariesfrance9.empsalnp1) AS sumempsalnp1ok
FROM
    salariesfrance9
GROUP BY
    salariesfrance9.ze2010lib;