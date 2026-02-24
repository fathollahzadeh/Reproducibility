
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
PostEngagement AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.VoteCount,
        RANK() OVER (ORDER BY (RP.VoteCount + RP.CommentCount + RP.Score) DESC) AS EngagementRank
    FROM 
        RankedPosts RP
)
SELECT 
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.ViewCount,
    PE.Score,
    PE.OwnerDisplayName,
    PE.CommentCount,
    PE.VoteCount,
    PE.EngagementRank
FROM 
    PostEngagement PE
WHERE 
    PE.EngagementRank <= 10
ORDER BY 
    PE.EngagementRank;
