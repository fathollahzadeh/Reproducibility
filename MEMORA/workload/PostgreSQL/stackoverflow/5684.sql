WITH UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ActivePostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ubc.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(ubc.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(ubc.BronzeBadgeCount, 0) AS BronzeBadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN UserBadgeCount ubc ON u.Id = ubc.UserId
    LEFT JOIN ActivePostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    CreationDate, 
    LastAccessDate, 
    BadgeCount, 
    GoldBadgeCount, 
    SilverBadgeCount, 
    BronzeBadgeCount, 
    TotalPosts, 
    Questions, 
    Answers, 
    TotalScore, 
    TotalViews
FROM UserPerformance
ORDER BY TotalScore DESC, Reputation DESC
LIMIT 10;