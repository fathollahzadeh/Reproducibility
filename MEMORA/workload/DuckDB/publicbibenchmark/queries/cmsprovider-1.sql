SELECT
    cmsprovider1.hcpcsdescription AS hcpcsdescription,
    CAST(cmsprovider1.nppesproviderzip AS BIGINT) AS nppesproviderzip,
    AVG(
        CAST(
            cmsprovider1.averagesubmittedchrgamt AS DOUBLE PRECISION
        )
    ) AS avgaveragesubmittedchrgamtok
FROM
    cmsprovider1
WHERE
    (
        (
            cmsprovider1.hcpcsdescription IN (
                'Removal of joint lining from two or more knee joint compartments using an endoscope',
                'Removal of knee cap',
                'Removal of knee joint covering'
            )
        )
        AND (cmsprovider1.nppesproviderstate = 'CA')
    )
GROUP BY
    cmsprovider1.hcpcsdescription,
    cmsprovider1.nppesproviderzip,
    cmsprovider1.nppesproviderzip;