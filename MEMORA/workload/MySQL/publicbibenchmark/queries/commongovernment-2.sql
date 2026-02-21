SELECT
    commongovernment13.agname AS agname,
    commongovernment13.fundingagencyname AS fundingagencyname,
    commongovernment13.level1category AS level1category,
    YEAR(DATE_ADD(CAST(commongovernment13.signeddate AS DATE), INTERVAL 3 MONTH)) AS yrsigneddateok
FROM
    commongovernment13
GROUP BY
    commongovernment13.agname,
    commongovernment13.fundingagencyname,
    commongovernment13.level1category,
    yrsigneddateok;