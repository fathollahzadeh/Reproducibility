WITH UserBadgeStats AS (
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
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(badge.BadgeCount, 0) AS BadgeCount,
        COALESCE(badge.GoldBadges, 0) AS GoldBadges,
        COALESCE(badge.SilverBadges, 0) AS SilverBadges,
        COALESCE(badge.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(post.TotalPosts, 0) AS TotalPosts,
        COALESCE(post.Questions, 0) AS Questions,
        COALESCE(post.Answers, 0) AS Answers,
        COALESCE(post.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats badge ON u.Id = badge.UserId
    LEFT JOIN 
        PostStats post ON u.Id = post.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS Rank
FROM 
    UserPerformance
WHERE 
    Reputation > 100
ORDER BY 
    Rank;
