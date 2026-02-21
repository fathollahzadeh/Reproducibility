SELECT
    pancreactomy22.hcpcscode AS hcpcscode,
    pancreactomy22.hcpcsdescription AS hcpcsdescription,
    CAST(pancreactomy22.npi AS BIGINT) AS npi,
    pancreactomy22.nppesproviderlastorgname AS nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate AS nppesproviderstate,
    pancreactomy22.providertype AS providertype,
    SUM(pancreactomy22.averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok,
    SUM(pancreactomy22.linesrvccnt) AS sumlinesrvccntok
FROM
    pancreactomy22
WHERE
    (
        (
            pancreactomy22.hcpcsdescription IN (
                'Biopsy of pancreas',
                'Imaging of bile duct and/or pancreas during surgery',
                'Imaging of bile ducts through existing catheter pancreas',
                'Injection for X-ray study of pancreas during surgery',
                'Needle biopsy of pancreas',
                'Placement of catheter of gallbladder and pancreas under imaging using an endoscope'
            )
        )
        AND (
            (
                pancreactomy22.providertype NOT IN ('', 'Clinical Laboratory')
            )
            OR (pancreactomy22.providertype IS NULL)
        )
    )
GROUP BY
    pancreactomy22.hcpcscode,
    pancreactomy22.hcpcsdescription,
    pancreactomy22.npi,
    pancreactomy22.nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate,
    pancreactomy22.providertype,
    pancreactomy22.npi;