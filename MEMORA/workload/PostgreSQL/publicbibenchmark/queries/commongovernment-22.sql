SELECT CAST(EXTRACT(YEAR FROM (cast(commongovernment2.signeddate as DATE) + 3 * INTERVAL '1' MONTH)) AS BIGINT) AS yrsigneddateok FROM commongovernment2 GROUP BY yrsigneddateok;
