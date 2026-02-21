-- SELECT
--     pancreactomy22.nppesproviderlastorgname AS nppesproviderlastorgname,
--     pancreactomy22.nppesproviderstate AS nppesproviderstate,
--     pancreactomy22.providertype AS providertype,
--     percentile_cont(0.5) WITHIN GROUP (ORDER BY pancreactomy22.averagemedicarepaymentamt) AS medaveragemedicarepaymentamtok,
--     percentile_cont(0.5) WITHIN GROUP (ORDER BY pancreactomy22.averagesubmittedchrgamt) AS medaveragesubmittedchrgamtok,
--     SUM(pancreactomy22.averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok,
--     SUM(pancreactomy22.linesrvccnt) AS sumlinesrvccntok
-- FROM
--     pancreactomy22
-- WHERE
--     (
--         (
--             pancreactomy22.providertype IN ('General Surgery', 'Surgical Oncology')
--         )
--         AND (
--             pancreactomy22.hcpcsdescription IN (
--                 'Pancreas procedure',
--                 'Partial removal of pancreas',
--                 'Partial removal of pancreas with attachment to small bowel',
--                 'Partial removal of pancreas, bile duct and small bowel with connection of pancreas to small bowel'
--             )
--         )
--     )
-- GROUP BY
--     pancreactomy22.nppesproviderlastorgname,
--     pancreactomy22.nppesproviderstate,
--     pancreactomy22.providertype;

WITH ranked AS (
  SELECT
    nppesproviderlastorgname,
    nppesproviderstate,
    providertype,
    averagemedicarepaymentamt,
    averagesubmittedchrgamt,
    linesrvccnt,
    ROW_NUMBER() OVER (
      PARTITION BY nppesproviderlastorgname, nppesproviderstate, providertype
      ORDER BY averagemedicarepaymentamt
    ) AS rn_amt,
    ROW_NUMBER() OVER (
      PARTITION BY nppesproviderlastorgname, nppesproviderstate, providertype
      ORDER BY averagesubmittedchrgamt
    ) AS rn_chrg,
    COUNT(*) OVER (
      PARTITION BY nppesproviderlastorgname, nppesproviderstate, providertype
    ) AS cnt
  FROM pancreactomy22
  WHERE providertype IN ('General Surgery', 'Surgical Oncology')
    AND hcpcsdescription IN (
      'Pancreas procedure',
      'Partial removal of pancreas',
      'Partial removal of pancreas with attachment to small bowel',
      'Partial removal of pancreas, bile duct and small bowel with connection of pancreas to small bowel'
    )
),
medians AS (
  SELECT
    nppesproviderlastorgname,
    nppesproviderstate,
    providertype,
    AVG(averagemedicarepaymentamt) AS medaveragemedicarepaymentamtok,
    AVG(averagesubmittedchrgamt) AS medaveragesubmittedchrgamtok
  FROM ranked
  WHERE
    rn_amt IN (FLOOR((cnt + 1)/2), CEIL((cnt + 1)/2)) AND
    rn_chrg IN (FLOOR((cnt + 1)/2), CEIL((cnt + 1)/2))
  GROUP BY
    nppesproviderlastorgname,
    nppesproviderstate,
    providertype
),
sums AS (
  SELECT
    nppesproviderlastorgname,
    nppesproviderstate,
    providertype,
    SUM(averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok,
    SUM(linesrvccnt) AS sumlinesrvccntok
  FROM pancreactomy22
  WHERE providertype IN ('General Surgery', 'Surgical Oncology')
    AND hcpcsdescription IN (
      'Pancreas procedure',
      'Partial removal of pancreas',
      'Partial removal of pancreas with attachment to small bowel',
      'Partial removal of pancreas, bile duct and small bowel with connection of pancreas to small bowel'
    )
  GROUP BY
    nppesproviderlastorgname,
    nppesproviderstate,
    providertype
)
SELECT
  m.nppesproviderlastorgname,
  m.nppesproviderstate,
  m.providertype,
  m.medaveragemedicarepaymentamtok,
  m.medaveragesubmittedchrgamtok,
  s.sumaveragemedicarepaymentamtok,
  s.sumlinesrvccntok
FROM medians m
JOIN sums s
  ON m.nppesproviderlastorgname = s.nppesproviderlastorgname
  AND m.nppesproviderstate = s.nppesproviderstate
  AND m.providertype = s.providertype;
