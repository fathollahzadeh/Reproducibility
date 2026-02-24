
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
),
PostHistoryMetrics AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    PM.PostId,
    PM.Title,
    PM.OwnerDisplayName,
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.CommentCount,
    PM.AnswerCount,
    PM.UpVotes,
    PM.DownVotes,
    PHM.EditCount,
    PHM.CloseCount,
    PHM.ReopenCount,
    PHM.DeleteCount
FROM 
    PostMetrics PM
LEFT JOIN 
    PostHistoryMetrics PHM ON PM.PostId = PHM.PostId
ORDER BY 
    PM.ViewCount DESC
LIMIT 100;
