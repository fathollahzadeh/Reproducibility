SELECT
    salariesfrance6.rome AS rome,
    salariesfrance6.romelib AS romelib,
    MIN(salariesfrance6.codgeoprincipal) AS mincodgeoprincipalnk,
    SUM(salariesfrance6.empsalnp1) AS sumempsalnp1ok
FROM
    salariesfrance6
GROUP BY
    salariesfrance6.rome,
    salariesfrance6.romelib
HAVING
    (
        SUM(salariesfrance6.empsalnp1) >= cast('0' as DOUBLE PRECISION)
    );