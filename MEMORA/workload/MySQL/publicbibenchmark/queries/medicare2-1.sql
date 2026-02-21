SELECT
    medicare21.providertype AS providertype
FROM
    medicare21
WHERE
    (medicare21.nppesproviderstate = 'NY')
GROUP BY
    medicare21.providertype
ORDER BY
    providertype ASC;