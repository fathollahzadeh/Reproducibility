WITH RecursivePostHistory AS (
    SELECT 
        Ph.Id AS PostHistoryId,
        Ph.PostId,
        Ph.PostHistoryTypeId,
        Ph.CreationDate AS HistoryCreationDate,
        P.Title AS PostTitle,
        U.DisplayName AS EditorName,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS HistoryVersion,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = Ph.PostId) AS TotalVotes,
        P.Score,
        P.ViewCount,
        CASE 
            WHEN Ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN Ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other Action'
        END AS ActionType
    FROM 
        PostHistory Ph
    INNER JOIN 
        Posts P ON Ph.PostId = P.Id
    LEFT JOIN 
        Users U ON Ph.UserId = U.Id
), 
LatestPostHistory AS (
    SELECT 
        *,
        MAX(HistoryVersion) OVER (PARTITION BY PostId) AS MaxVersion
    FROM 
        RecursivePostHistory
)
SELECT 
    LPH.PostHistoryId,
    LPH.PostId,
    LPH.PostTitle,
    LPH.ActionType,
    LPH.HistoryCreationDate,
    LPH.EditorName,
    LPH.TotalVotes,
    LPH.Score,
    LPH.ViewCount,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Tags T 
     INNER JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
     WHERE P.Id = LPH.PostId) AS Tags,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Comments C 
         WHERE C.PostId = LPH.PostId 
           AND C.CreationDate > LPH.HistoryCreationDate), 
        0) AS NewCommentsSinceHistory
FROM 
    LatestPostHistory LPH
WHERE 
    LPH.MaxVersion = LPH.HistoryVersion
ORDER BY 
    LPH.HistoryCreationDate DESC
LIMIT 100;

