
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
RecentUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS RecentPostsCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '3 month'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rb.BadgeCount,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    phs.EditCount,
    phs.CloseOpenCount,
    rup.RecentPostsCount
FROM 
    Users up
JOIN 
    UserBadges rb ON up.Id = rb.UserId
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
LEFT JOIN 
    RecentUserPosts rup ON up.Id = rup.OwnerUserId
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, rp.Score DESC;
