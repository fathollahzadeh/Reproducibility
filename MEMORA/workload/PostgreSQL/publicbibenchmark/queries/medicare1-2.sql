SELECT
    medicare12.calculation3170826185336909 AS calculation3170826185336909,
    medicare12.calculation9030826185528129 AS calculation9030826185528129,
    medicare12.drugname AS drugname,
    CAST(medicare12.npi AS BIGINT) AS npi,
    medicare12.nppesproviderstate AS nppesproviderstate
FROM
    medicare12
WHERE
    (
        (
            NOT (
                medicare12.drugname IN ('GENOTROPIN', 'OCTAGAM', 'PEGINTRON REDIPEN')
            )
        )
        OR (medicare12.drugname IS NULL)
    )
    AND EXISTS (
        SELECT
            1 AS one
        FROM
            (
                SELECT
                    t0.drugname AS drugname
                FROM
                    (
                        SELECT
                            medicare12.drugname AS drugname,
                            MIN(1) AS tableaujoinflag,
                            AVG(
                                CAST(
                                    medicare12.calculation3170826185505725 AS DOUBLE PRECISION
                                )
                            ) AS measure0
                        FROM
                            medicare12
                        GROUP BY
                            medicare12.drugname
                        ORDER BY
                            measure0 DESC
                        LIMIT
                            100
                    ) t0
                WHERE
                    (
                        (
                            NOT (
                                t0.drugname IN ('GENOTROPIN', 'OCTAGAM', 'PEGINTRON REDIPEN')
                            )
                        )
                        OR (t0.drugname IS NULL)
                    )
            ) t1
        WHERE
            (
                (medicare12.drugname = t1.drugname)
                or (
                    medicare12.drugname is null
                    and t1.drugname is null
                )
            )
    )
GROUP BY
    medicare12.calculation3170826185336909,
    medicare12.calculation9030826185528129,
    medicare12.drugname,
    medicare12.npi,
    medicare12.nppesproviderstate,
    medicare12.npi;