WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(P.AvgScore, 0) AS AvgScore,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN UserBadges B ON U.Id = B.UserId
)
SELECT 
    UD.UserId,
    UD.DisplayName,
    UD.TotalPosts,
    UD.TotalViews,
    UD.AvgScore,
    UD.BadgeCount,
    UD.GoldBadges,
    UD.SilverBadges,
    UD.BronzeBadges,
    CASE 
        WHEN UD.BadgeCount > 0 THEN 'Active'
        WHEN UD.TotalPosts = 0 AND UD.TotalViews = 0 THEN 'Inactive'
        ELSE 'Leverage'
    END AS UserActivity,
    CASE 
        WHEN UD.AvgScore < 5 THEN 'Beginner'
        WHEN UD.AvgScore BETWEEN 5 AND 15 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserExpertise
FROM UserPostDetails UD
WHERE UD.TotalPosts > (
    SELECT AVG(TotalPosts) FROM UserPostDetails
) OR UD.BadgeCount > (
    SELECT AVG(BadgeCount) FROM UserBadges
)
ORDER BY UD.TotalPosts DESC, UD.BadgeCount DESC
LIMIT 50;