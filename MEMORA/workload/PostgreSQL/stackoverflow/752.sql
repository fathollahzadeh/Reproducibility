WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.PostTypeId = 1
), 
HighestScoredPost AS (
    SELECT 
        rp.OwnerDisplayName,
        MAX(rp.Score) AS MaxScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    GROUP BY 
        rp.OwnerDisplayName
),
CommentStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN c.Score IS NULL THEN 0 ELSE c.Score END) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 2
    GROUP BY 
        p.OwnerUserId
) 
SELECT 
    u.DisplayName,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    COALESCE(cs.TotalCommentScore, 0) AS TotalCommentScore,
    hs.MaxScore
FROM 
    Users u
LEFT JOIN 
    CommentStats cs ON u.Id = cs.OwnerUserId
LEFT JOIN 
    HighestScoredPost hs ON u.DisplayName = hs.OwnerDisplayName
WHERE 
    u.Reputation > 1000
AND 
    (hs.MaxScore IS NOT NULL OR cs.TotalComments > 0)
ORDER BY 
    u.Reputation DESC;