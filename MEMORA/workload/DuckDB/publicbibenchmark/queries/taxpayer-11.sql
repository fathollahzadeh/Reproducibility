SELECT
    taxpayer5.nppesproviderstate AS nppesproviderstate
FROM
    taxpayer5
WHERE
    (
        (
            taxpayer5.nppesproviderfirstname = 'JOHN'
        )
        AND (
            taxpayer5.nppesproviderlastorgname = 'HOLDER'
        )
    )
GROUP BY
    taxpayer5.nppesproviderstate;