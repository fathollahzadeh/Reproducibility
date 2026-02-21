SELECT
    pancreactomy21.nppesproviderlastorgname AS nppesproviderlastorgname,
    pancreactomy21.nppesproviderstate AS nppesproviderstate,
    CAST(pancreactomy21.nppesproviderzip AS BIGINT) AS nppesproviderzip,
    pancreactomy21.providertype AS providertype,
    SUM(pancreactomy21.linesrvccnt) AS sumlinesrvccntok
FROM
    pancreactomy21
WHERE
    (
        pancreactomy21.hcpcsdescription = 'Imaging of pancreatic duct for placement of catheter using an endoscope'
    )
GROUP BY
    pancreactomy21.nppesproviderlastorgname,
    pancreactomy21.nppesproviderstate,
    pancreactomy21.nppesproviderzip,
    pancreactomy21.providertype,
    pancreactomy21.nppesproviderzip;