WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        COUNT(rp.PostId) AS RecentPostCount
    FROM
        UserBadges ub
    JOIN 
        RecentPosts rp ON ub.UserId = rp.OwnerUserId
    GROUP BY 
        ub.UserId, ub.DisplayName, ub.BadgeCount
    ORDER BY 
        ub.BadgeCount DESC, RecentPostCount DESC
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.RecentPostCount
FROM 
    TopUsers tu
WHERE 
    tu.BadgeCount > 0
LIMIT 10;