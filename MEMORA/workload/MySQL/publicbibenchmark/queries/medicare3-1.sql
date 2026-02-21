SELECT
    medicare31.nppesprovidercountry AS nppesprovidercountry,
    medicare31.nppesproviderstate AS nppesproviderstate,
    SUM(medicare31.averagemedicareallowedamt) AS sumaveragemedicareallowedamtok
FROM
    medicare31
WHERE
    (
        medicare31.providertype IN (
            'Physical Medicine and Rehabilitation',
            'Physical Therapist'
        )
    )
GROUP BY
    medicare31.nppesprovidercountry,
    medicare31.nppesproviderstate;