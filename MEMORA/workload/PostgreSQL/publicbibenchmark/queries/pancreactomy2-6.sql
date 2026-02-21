SELECT
    pancreactomy22.nppesproviderlastorgname AS nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate AS nppesproviderstate,
    CAST(pancreactomy22.nppesproviderzip AS BIGINT) AS nppesproviderzip,
    pancreactomy22.providertype AS providertype,
    SUM(pancreactomy22.linesrvccnt) AS sumlinesrvccntok
FROM
    pancreactomy22
WHERE
    (
        pancreactomy22.hcpcsdescription = 'Imaging of pancreatic duct for placement of catheter using an endoscope'
    )
GROUP BY
    pancreactomy22.nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate,
    pancreactomy22.nppesproviderzip,
    pancreactomy22.providertype,
    pancreactomy22.nppesproviderzip;