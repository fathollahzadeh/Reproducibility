SELECT
    AVG(
        CAST(
            (
                taxpayer8.averagemedicareallowedamt - taxpayer8.averagemedicarepaymentamt
            ) AS DOUBLE PRECISION
        )
    ) AS avgcalculation9940518082838207ok,
    AVG(
        CAST(
            taxpayer8.averagemedicareallowedamt AS DOUBLE PRECISION
        )
    ) AS avgaveragemedicareallowedamtok,
    AVG(
        CAST(
            taxpayer8.averagemedicarepaymentamt AS DOUBLE PRECISION
        )
    ) AS avgaveragemedicarepaymentamtok,
    AVG(
        CAST(
            taxpayer8.averagesubmittedchrgamt AS DOUBLE PRECISION
        )
    ) AS avgaveragesubmittedchrgamtok,
    taxpayer8.hcpcsdescription AS hcpcsdescription
FROM
    taxpayer8
WHERE
    (
        (
            taxpayer8.nppesproviderfirstname = 'JOHN'
        )
        AND (
            taxpayer8.nppesproviderlastorgname = 'HOLDER'
        )
        AND (taxpayer8.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer8.hcpcsdescription;