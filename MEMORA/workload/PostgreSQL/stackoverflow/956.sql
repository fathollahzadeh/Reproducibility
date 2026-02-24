
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.RankScore,
        bu.BadgeCount,
        bu.HighestBadge,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'High' 
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium' 
            ELSE 'Low' 
        END AS ViewRank
    FROM 
        RankedPosts rp
    JOIN 
        BadgedUsers bu ON rp.OwnerUserId = bu.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.RankScore,
    pm.BadgeCount,
    pm.HighestBadge,
    pm.ViewRank,
    COALESCE(COUNT(v.Id), 0) AS VoteCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId) AS TotalComments
FROM 
    PostMetrics pm
LEFT JOIN 
    Votes v ON pm.PostId = v.PostId
GROUP BY 
    pm.PostId, pm.Title, pm.CreationDate, pm.RankScore, pm.BadgeCount, pm.HighestBadge, pm.ViewRank
HAVING 
    pm.RankScore <= 3
ORDER BY 
    pm.RankScore ASC, pm.BadgeCount DESC;
