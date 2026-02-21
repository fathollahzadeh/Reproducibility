SELECT
    DATE_FORMAT(EventTime, '%Y-%m-%d %H:00:00') AS M,
    COUNT(*) AS PageViews
FROM
    hits
WHERE
    CounterID = 62
    AND EventDate >= '2013-07-14'
    AND EventDate <= '2013-07-15'
    AND IsRefresh = 0
    AND DontCountHits = 0
GROUP BY
    DATE_FORMAT(EventTime, '%Y-%m-%d %H:00:00')
ORDER BY
    DATE_FORMAT(EventTime, '%Y-%m-%d %H:00:00')
LIMIT
    10 OFFSET 1000;