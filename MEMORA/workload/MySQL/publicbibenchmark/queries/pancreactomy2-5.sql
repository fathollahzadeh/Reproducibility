SELECT
    pancreactomy22.nppesproviderlastorgname AS nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate AS nppesproviderstate,
    AVG(
        CAST(
            pancreactomy22.averagemedicareallowedamt AS DOUBLE PRECISION
        )
    ) AS avgaveragemedicareallowedamtok,
    AVG(
        CAST(
            pancreactomy22.averagemedicarepaymentamt AS DOUBLE PRECISION
        )
    ) AS avgaveragemedicarepaymentamtok,
    AVG(
        CAST(
            pancreactomy22.averagesubmittedchrgamt AS DOUBLE PRECISION
        )
    ) AS avgaveragesubmittedchrgamtok,
    COUNT(pancreactomy22.averagemedicareallowedamt) AS cntaveragemedicareallowedamtok,
    COUNT(pancreactomy22.averagemedicarepaymentamt) AS cntaveragemedicarepaymentamtok,
    COUNT(pancreactomy22.averagesubmittedchrgamt) AS cntaveragesubmittedchrgamtok,
    SUM(pancreactomy22.averagemedicareallowedamt) AS sumaveragemedicareallowedamtok,
    SUM(pancreactomy22.averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok,
    SUM(pancreactomy22.averagesubmittedchrgamt) AS sumaveragesubmittedchrgamtok,
    SUM(pancreactomy22.linesrvccnt) AS sumlinesrvccntok
FROM
    pancreactomy22
WHERE
    (
        (
            pancreactomy22.hcpcsdescription IN (
                'Pancreas procedure',
                'Partial removal of pancreas',
                'Partial removal of pancreas with attachment to small bowel',
                'Partial removal of pancreas, bile duct and small bowel with connection of pancreas to small bowel'
            )
        )
        AND (
            pancreactomy22.providertype IN (
                'General Surgery',
                'Surgical Oncology',
                'Vascular Surgery'
            )
        )
    )
GROUP BY
    pancreactomy22.nppesproviderlastorgname,
    pancreactomy22.nppesproviderstate;