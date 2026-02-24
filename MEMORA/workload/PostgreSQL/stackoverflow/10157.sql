WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownvoteCount,
        COALESCE((SELECT COUNT(*) FROM Badges B WHERE B.UserId = P.OwnerUserId), 0) AS BadgeCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
),

PostHistoryEngagement AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PHT.Name
)

SELECT 
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.ViewCount,
    PE.Score,
    PE.CommentCount,
    PE.UpvoteCount,
    PE.DownvoteCount,
    PE.BadgeCount,
    PE.OwnerReputation,
    PE.OwnerDisplayName,
    COALESCE(PHE.HistoryCount, 0) AS EditCount,
    COALESCE(PHE.HistoryCount, 0) AS ClosingCount
FROM 
    PostEngagement PE
LEFT JOIN 
    PostHistoryEngagement PHE ON PE.PostId = PHE.PostId
ORDER BY 
    PE.ViewCount DESC;