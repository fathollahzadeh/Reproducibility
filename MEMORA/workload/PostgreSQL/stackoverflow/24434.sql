
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        RANK() OVER (PARTITION BY PT.Id ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
), 
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.PostType
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 3
), 
PostWithComments AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.ViewCount,
        TP.Score,
        COALESCE(C.Count, 0) AS CommentCount,
        CASE 
            WHEN COALESCE(C.Count, 0) = 0 THEN 'No Comments'
            ELSE 'Comments Available'
        END AS CommentStatus
    FROM 
        TopPosts TP
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count 
         FROM Comments 
         GROUP BY PostId) C ON TP.PostId = C.PostId
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users U
), 
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)

SELECT 
    PWC.Title,
    PWC.ViewCount,
    PWC.Score,
    PWC.CommentCount,
    PWC.CommentStatus,
    U.Reputation,
    U.ReputationCategory,
    PHS.EditCount,
    PHS.LastEditDate
FROM 
    PostWithComments PWC
JOIN 
    UserReputation U ON PWC.PostId = U.UserId 
LEFT JOIN 
    PostHistorySummary PHS ON PWC.PostId = PHS.PostId
WHERE 
    PWC.CommentCount > 0
    AND (U.Reputation IS NOT NULL AND U.Reputation < 1000)
ORDER BY 
    PWC.Score DESC, PWC.Title
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
