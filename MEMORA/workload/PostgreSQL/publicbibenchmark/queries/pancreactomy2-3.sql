SELECT
    pancreactomy22.nppesprovidergender AS nppesprovidergender,
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
            pancreactomy22.providertype IN (
                'General Surgery',
                'Surgical Oncology',
                'Vascular Surgery'
            )
        )
        AND (
            pancreactomy22.hcpcsdescription IN (
                'Pancreas procedure',
                'Partial removal of pancreas',
                'Partial removal of pancreas with attachment to small bowel',
                'Partial removal of pancreas, bile duct and small bowel with connection of pancreas to small bowel'
            )
        )
    )
GROUP BY
    pancreactomy22.nppesprovidergender,
    pancreactomy22.nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate,
    pancreactomy22.providertype;