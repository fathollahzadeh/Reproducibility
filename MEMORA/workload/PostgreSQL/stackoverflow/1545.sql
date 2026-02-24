WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),

PostClosureSummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ClosureCount,
        STRING_AGG(CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            ELSE 'Reopened'
        END, ', ') AS ClosureHistory
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY PH.PostId
)

SELECT 
    U.DisplayName,
    UV.Upvotes,
    UV.Downvotes,
    UV.TotalPosts,
    UV.AvgScore,
    COALESCE(PCS.ClosureCount, 0) AS ClosureCount,
    COALESCE(PCS.ClosureHistory, 'No Closure History') AS ClosureHistory
FROM UserVoteSummary UV
JOIN Users U ON UV.UserId = U.Id
LEFT JOIN PostClosureSummary PCS ON PCS.PostId = U.Id
WHERE UV.TotalPosts > 5
ORDER BY UV.AvgScore DESC, UV.Upvotes - UV.Downvotes DESC
LIMIT 10;
