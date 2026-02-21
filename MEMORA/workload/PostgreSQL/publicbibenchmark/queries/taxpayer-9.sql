SELECT
    taxpayer3.nppesproviderstate AS nppesproviderstate
FROM
    taxpayer3
WHERE
    (
        (
            taxpayer3.nppesproviderfirstname = 'JOHN'
        )
        AND (
            taxpayer3.nppesproviderlastorgname = 'HOLDER'
        )
    )
GROUP BY
    taxpayer3.nppesproviderstate;