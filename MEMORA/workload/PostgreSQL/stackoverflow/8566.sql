WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN 1 ELSE 0 END) AS QuestionAnswerCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredPostsCount,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(bp.PostCount, 0)) AS TotalPosts,
        SUM(COALESCE(ba.BadgeCount, 0)) AS TotalBadges,
        SUM(COALESCE(ba.GoldBadges, 0)) AS TotalGoldBadges,
        SUM(COALESCE(ba.SilverBadges, 0)) AS TotalSilverBadges,
        SUM(COALESCE(ba.BronzeBadges, 0)) AS TotalBronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        UserActivity bp ON u.Id = bp.UserId
    LEFT JOIN 
        UserBadges ba ON u.Id = ba.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.TotalPosts,
    up.TotalBadges,
    up.TotalGoldBadges,
    up.TotalSilverBadges,
    up.TotalBronzeBadges,
    ua.PostCount,
    ua.QuestionAnswerCount,
    ua.HighViewCountPosts,
    ua.AnsweredPostsCount,
    ua.Reputation,
    ua.ReputationRank
FROM 
    UserPosts up
JOIN 
    Users u ON up.UserId = u.Id
JOIN 
    UserActivity ua ON up.UserId = ua.UserId
WHERE 
    up.TotalPosts > 10
ORDER BY 
    ua.Reputation DESC, up.TotalPosts DESC;
