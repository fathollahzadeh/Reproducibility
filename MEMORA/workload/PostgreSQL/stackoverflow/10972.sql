
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, U.DisplayName
),
PostHistoryMetrics AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.AnswerCount,
    PM.CommentCount,
    PM.OwnerDisplayName,
    PM.Upvotes,
    PM.Downvotes,
    COALESCE(PHM.CloseCount, 0) AS CloseCount,
    COALESCE(PHM.ReopenCount, 0) AS ReopenCount
FROM PostMetrics PM
LEFT JOIN PostHistoryMetrics PHM ON PM.PostId = PHM.PostId
ORDER BY PM.Score DESC, PM.ViewCount DESC
LIMIT 100;
