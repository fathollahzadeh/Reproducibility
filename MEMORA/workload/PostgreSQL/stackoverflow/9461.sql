WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts AS P
    JOIN 
        Users AS U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND P.PostTypeId IN (1, 2)  
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
),
PostDetails AS (
    SELECT 
        TRP.*,
        C.CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        TopRankedPosts AS TRP
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS C ON TRP.PostId = C.PostId
    LEFT JOIN 
        Votes AS V ON TRP.PostId = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        TRP.PostId, TRP.Title, TRP.Score, TRP.ViewCount, TRP.OwnerDisplayName, C.CommentCount
)
SELECT 
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.OwnerDisplayName,
    PD.CommentCount,
    PD.TotalBounty
FROM 
    PostDetails AS PD
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC;