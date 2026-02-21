SELECT
    YEAR(DATE_ADD(CAST(commongovernment2.signeddate AS DATE), INTERVAL 3 MONTH)) AS yrsigneddateok
FROM
    commongovernment2
GROUP BY
    yrsigneddateok;