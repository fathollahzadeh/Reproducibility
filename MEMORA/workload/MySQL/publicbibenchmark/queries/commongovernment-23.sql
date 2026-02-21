SELECT
    YEAR(DATE_ADD(CAST(commongovernment4.signeddate AS DATE), INTERVAL 3 MONTH)) AS yrsigneddateok
FROM
    commongovernment4
GROUP BY
    yrsigneddateok;