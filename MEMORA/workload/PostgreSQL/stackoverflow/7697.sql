WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.CommentCount > 0 THEN 1 ELSE 0 END) AS CommentedPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ap.TotalPosts, 0) AS TotalPosts,
        COALESCE(ap.PositivePosts, 0) AS PositivePosts,
        COALESCE(ap.CommentedPosts, 0) AS CommentedPosts,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        UserBadges ub
    LEFT JOIN 
        ActivePosts ap ON ub.UserId = ap.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.CommentedPosts,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    RANK() OVER (ORDER BY us.BadgeCount DESC, us.TotalPosts DESC) AS UserRank
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 5 
ORDER BY 
    UserRank;