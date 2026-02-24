
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
HighScoringUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 50
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.HighestBadgeClass, 0) AS UserHighestBadgeClass,
    CASE 
        WHEN r.PostRank = 1 THEN 'Best Post'
        ELSE 'Regular Post'
    END AS PostQuality
FROM 
    RankedPosts r
JOIN 
    HighScoringUsers u ON r.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.UserId)
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
WHERE 
    r.CommentCount > 10
ORDER BY 
    r.Score DESC,
    r.ViewCount DESC;
