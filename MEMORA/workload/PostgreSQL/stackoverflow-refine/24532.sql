
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, '1970-01-01') AS RecentPostDate,
    COALESCE(rp.Score, 0) AS PostScore,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver Badge Holder'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
                    AND rp.rn = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Votes v
        WHERE v.UserId = u.Id AND v.VoteTypeId = 3 
    )
ORDER BY 
    ub.BadgeCount DESC, u.Reputation DESC
LIMIT 50;
