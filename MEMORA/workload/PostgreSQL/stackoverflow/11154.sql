
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(PH.Id) AS EditCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount, P.Score
),
AveragePerformance AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(VoteCount) AS AvgVoteCount,
        AVG(EditCount) AS AvgEditCount
    FROM PostStatistics
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.VoteCount,
    PS.EditCount,
    AP.AvgViewCount,
    AP.AvgScore,
    AP.AvgCommentCount,
    AP.AvgVoteCount,
    AP.AvgEditCount
FROM PostStatistics PS
CROSS JOIN AveragePerformance AP
ORDER BY PS.Score DESC, PS.ViewCount DESC;
