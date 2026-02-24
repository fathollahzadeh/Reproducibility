WITH BenchmarkedQueries AS (
    SELECT
        PH.PostHistoryTypeId,
        COUNT(*) AS Count,
        MIN(PH.CreationDate) AS FirstOccurrence,
        MAX(PH.CreationDate) AS LastOccurrence,
        MAX(PH.CreationDate) - MIN(PH.CreationDate) AS Duration
    FROM
        PostHistory PH
    JOIN
        Posts P ON PH.PostId = P.Id
    WHERE
        PH.CreationDate > '2023-01-01' 
    GROUP BY
        PH.PostHistoryTypeId
)
SELECT
    PHT.Name,
    BQ.Count,
    BQ.FirstOccurrence,
    BQ.LastOccurrence,
    BQ.Duration
FROM
    BenchmarkedQueries BQ
JOIN
    PostHistoryTypes PHT ON BQ.PostHistoryTypeId = PHT.Id
ORDER BY
    BQ.Count DESC;