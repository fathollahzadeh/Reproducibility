WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(com.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.BadgeCount,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate::date, NULL) AS RecentPostDate,
    COALESCE(rp.Score, 0) AS RecentPostScore,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Comments present' 
        ELSE 'No comments'
    END AS CommentStatus
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.Id = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    au.Reputation DESC, 
    RecentPostScore DESC
LIMIT 10;