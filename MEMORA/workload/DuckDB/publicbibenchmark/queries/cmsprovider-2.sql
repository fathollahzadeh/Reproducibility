SELECT
    cmsprovider2.hcpcsdescription AS hcpcsdescription,
    CAST(cmsprovider2.nppesproviderzip AS BIGINT) AS nppesproviderzip,
    AVG(
        CAST(
            cmsprovider2.averagesubmittedchrgamt AS DOUBLE PRECISION
        )
    ) AS avgaveragesubmittedchrgamtok
FROM
    cmsprovider2
WHERE
    (
        (
            cmsprovider2.hcpcsdescription IN (
                'Removal of joint lining from two or more knee joint compartments using an endoscope',
                'Removal of knee cap',
                'Removal of knee joint covering'
            )
        )
        AND (cmsprovider2.nppesproviderstate = 'CA')
    )
GROUP BY
    cmsprovider2.hcpcsdescription,
    cmsprovider2.nppesproviderzip,
    cmsprovider2.nppesproviderzip;