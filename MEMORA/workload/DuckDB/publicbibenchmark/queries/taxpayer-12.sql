SELECT
    taxpayer6.nppesprovidercity AS nppesprovidercity
FROM
    taxpayer6
WHERE
    (
        (
            taxpayer6.hcpcsdescription = 'Initial hospital care'
        )
        AND (taxpayer6.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer6.nppesprovidercity;