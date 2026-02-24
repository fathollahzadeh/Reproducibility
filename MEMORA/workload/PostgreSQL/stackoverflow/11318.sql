WITH user_post_counts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
user_badges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.CommentCount,
    up.UpvotedPostCount,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(ub.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadgeCount, 0) AS BronzeBadges
FROM 
    user_post_counts up
LEFT JOIN 
    user_badges ub ON up.UserId = ub.UserId
ORDER BY 
    up.PostCount DESC;