SELECT
    taxpayer4.nppesprovidercity AS nppesprovidercity
FROM
    taxpayer4
WHERE
    (
        (
            taxpayer4.nppesproviderfirstname = 'JOHN'
        )
        AND (
            taxpayer4.nppesproviderlastorgname = 'HOLDER'
        )
        AND (taxpayer4.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer4.nppesprovidercity;