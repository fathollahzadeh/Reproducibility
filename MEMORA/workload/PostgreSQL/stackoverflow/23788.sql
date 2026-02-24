WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

PostAggregates AS (
    SELECT 
        PostId,
        MAX(ViewCount) AS MaxViews,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeScores,
        STRING_AGG(Tags, ', ') AS AllTags
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
)

SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.BadgeCount,
    pa.MaxViews,
    pa.PositiveScores,
    pa.NegativeScores,
    rp.Rank,
    rp.Title,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    (CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.Rank BETWEEN 2 AND 5 THEN 'High Rank Post'
        ELSE 'Low Rank Post'
     END) AS RankClassification
FROM 
    UserReputation ur
JOIN 
    PostAggregates pa ON ur.UserId = (SELECT OwnerUserId FROM RankedPosts WHERE PostId = pa.PostId)
JOIN 
    RankedPosts rp ON pa.PostId = rp.PostId
WHERE 
    pa.MaxViews IS NOT NULL
    AND (ur.Reputation > 100 OR ur.BadgeCount > 1)
ORDER BY 
    ur.Reputation DESC,
    pa.MaxViews DESC,
    rp.Title;