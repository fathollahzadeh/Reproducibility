
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount,
        P.CreationDate, 
        U.DisplayName AS OwnerName, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS UpvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, U.DisplayName
), PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.Score, 
    RP.ViewCount, 
    RP.OwnerName, 
    RP.CommentCount, 
    RP.UpvoteCount,
    PHS.LastEditDate, 
    PHS.EditCount,
    CASE 
        WHEN RP.Score > 50 THEN 'Popular'
        WHEN RP.Score BETWEEN 20 AND 50 THEN 'Moderate'
        ELSE 'New'
    END AS PopularityRank
FROM 
    RecentPosts RP
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
ORDER BY 
    RP.ViewCount DESC, RP.Score DESC;
