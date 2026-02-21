SELECT
    taxpayer9.nppesproviderstreet1 AS nppesproviderstreet1
FROM
    taxpayer9
WHERE
    (
        (
            taxpayer9.nppesproviderfirstname = 'JOHN'
        )
        AND (
            taxpayer9.nppesproviderlastorgname = 'HOLDER'
        )
        AND (taxpayer9.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer9.nppesproviderstreet1;