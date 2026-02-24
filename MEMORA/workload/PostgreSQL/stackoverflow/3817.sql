
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ur.DisplayName AS TopUser,
        ur.Reputation AS UserReputation,
        cs.TotalComments,
        cs.AvgCommentScore,
        COALESCE(pl.Id, 0) AS RelatedPostLink
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON ur.UserRank = 1 
    LEFT JOIN 
        Posts pl ON pl.Id = rp.PostId
    LEFT JOIN 
        CommentStats cs ON cs.PostId = rp.PostId
)
SELECT 
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.TopUser,
    pa.UserReputation,
    pa.TotalComments,
    pa.AvgCommentScore,
    CASE 
        WHEN pa.RelatedPostLink = 0 THEN 'No related links' 
        ELSE 'Has related post' 
    END AS RelationStatus
FROM 
    PostAnalysis pa
WHERE 
    pa.Score IS NOT NULL 
    AND pa.ViewCount > 100
ORDER BY 
    pa.Score DESC, pa.UserReputation DESC
LIMIT 10;
