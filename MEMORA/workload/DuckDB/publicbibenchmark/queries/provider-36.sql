SELECT
    (
        CASE
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'Provider 1'
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'Provider 2'
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'Provider 3'
            ELSE 'Others'
        END
    ) AS calculation0640528144651213,
    (
        CASE
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'highlight'
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'highlight'
            WHEN (provider6.nppesproviderlastorgname = '') THEN 'highlight'
            ELSE 'do not highlight'
        END
    ) AS highlightnamecolorcopy,
    MAX(provider6.nppesproviderfirstname) AS tempattrnppesproviderfirstnamenk29377077860,
    MIN(provider6.nppesproviderfirstname) AS tempattrnppesproviderfirstnamenk8307197000,
    MIN(provider6.nppesproviderlastorgname) AS tempattrnppesproviderlastorgnamenk16434054750,
    MAX(provider6.nppesproviderlastorgname) AS tempattrnppesproviderlastorgnamenk8743648680,
    CAST(provider6.npi AS BIGINT) AS npi,
    SUM(
        (
            CAST(
                provider6.averagesubmittedchrgamt AS DOUBLE PRECISION
            ) * CAST(
                CAST(provider6.benedaysrvccnt AS BIGINT) AS DOUBLE PRECISION
            )
        )
    ) AS sumcalculation0780503000625693ok,
    SUM(
        (
            CAST(
                provider6.averagemedicareallowedamt AS DOUBLE PRECISION
            ) * CAST(
                CAST(provider6.linesrvccnt AS BIGINT) AS DOUBLE PRECISION
            )
        )
    ) AS sumcalculation4590518083015070ok,
    SUM(
        (
            CAST(
                provider6.averagemedicarepaymentamt AS DOUBLE PRECISION
            ) * CAST(
                CAST(provider6.linesrvccnt AS BIGINT) AS DOUBLE PRECISION
            )
        )
    ) AS sumcalculation5700503000537352ok
FROM
    provider6
WHERE
    (
        (provider6.nppesproviderstate = 'WA')
        AND (provider6.providertype = 'Nephrology')
    )
GROUP BY
    calculation0640528144651213,
    highlightnamecolorcopy,
    provider6.npi,
    npi;