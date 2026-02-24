
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(c.CommentsCount, 0) AS CommentsCount
FROM 
    UserBadges up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentsCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON rp.PostId = c.PostId
WHERE 
    rp.OwnerPostRank = 1
ORDER BY 
    up.BadgeCount DESC, 
    rp.Score DESC;
