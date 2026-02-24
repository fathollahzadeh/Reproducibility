WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        1 AS Level,
        NULL AS ParentId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.Score,
        a.ViewCount,
        a.CreationDate,
        ph.Level + 1 AS Level,
        ph.PostId AS ParentId
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2 
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.Level,
    p.CreationDate,
    RANK() OVER (PARTITION BY p.Level ORDER BY p.Score DESC) AS ScoreRank
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHierarchy p ON u.Id = p.PostId
GROUP BY 
    u.Id, u.DisplayName, p.PostId, p.Title, p.Score, p.ViewCount, p.Level, p.CreationDate
HAVING 
    COUNT(b.Id) > 0 OR COUNT(p.PostId) > 0
ORDER BY 
    p.Level, ScoreRank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;