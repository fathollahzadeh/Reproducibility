SELECT
    taxpayer7.nppesproviderlastorgname AS nppesproviderlastorgname
FROM
    taxpayer7
WHERE
    (
        (
            taxpayer7.nppesproviderfirstname = 'JOHN'
        )
        AND (taxpayer7.nppesproviderstate = 'WA')
    )
GROUP BY
    taxpayer7.nppesproviderlastorgname;