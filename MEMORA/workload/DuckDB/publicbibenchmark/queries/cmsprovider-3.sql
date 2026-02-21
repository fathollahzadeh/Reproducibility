SELECT
    cmsprovider2.hcpcsdescription AS hcpcsdescription,
    CAST(cmsprovider2.nppesproviderzip AS BIGINT) AS nppesproviderzip,
    SUM(cmsprovider2.averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok
FROM
    cmsprovider2
WHERE
    (cmsprovider2.nppesproviderstate = 'CA')
GROUP BY
    cmsprovider2.hcpcsdescription,
    cmsprovider2.nppesproviderzip,
    cmsprovider2.nppesproviderzip;