SELECT CAST(EXTRACT(YEAR FROM (cast(commongovernment4.signeddate as DATE) + 3 * INTERVAL '1' MONTH)) AS BIGINT) AS yrsigneddateok FROM commongovernment4 GROUP BY yrsigneddateok;
