WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Reputation = ur.Reputation / 2
)
, RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
, UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    COALESCE(rb.Badges, 'No Badges') AS Badges,
    rp.Title AS RecentPostTitle,
    rp.ViewCount AS RecentPostViewCount,
    CASE 
        WHEN rp.ViewCount IS NOT NULL THEN ROUND(COALESCE(100.0 * rp.ViewCount / NULLIF((
            SELECT 
                SUM(ViewCount) 
            FROM 
                Posts p2
            WHERE 
                p2.OwnerUserId = u.Id
        ), 0), 0), 2)
        ELSE 0
    END AS ViewPercentage
FROM 
    Users u
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    u.Reputation DESC
LIMIT 10;