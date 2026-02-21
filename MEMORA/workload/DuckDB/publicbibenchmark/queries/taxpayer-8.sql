SELECT
    taxpayer2.nppesproviderlastorgname AS nppesproviderlastorgname
FROM
    taxpayer2
WHERE
    (
        (
            taxpayer2.nppesproviderfirstname = 'JOHN'
        )
        AND (taxpayer2.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer2.nppesproviderlastorgname;