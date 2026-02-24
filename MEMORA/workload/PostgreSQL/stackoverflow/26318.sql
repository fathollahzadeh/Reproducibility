WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.FavoriteCount) AS TotalFavorites
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(E.TotalPosts, 0) AS TotalPosts,
        COALESCE(E.TotalViews, 0) AS TotalViews,
        COALESCE(E.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(E.TotalComments, 0) AS TotalComments,
        COALESCE(E.TotalFavorites, 0) AS TotalFavorites
    FROM Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    LEFT JOIN PostEngagement E ON U.Id = E.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.TotalPosts,
    U.TotalViews,
    U.TotalAnswers,
    U.TotalComments,
    U.TotalFavorites,
    RANK() OVER (ORDER BY U.TotalViews DESC) AS ViewRank,
    RANK() OVER (ORDER BY U.TotalPosts DESC) AS PostRank
FROM UserStats U
ORDER BY U.TotalViews DESC, U.TotalPosts DESC
LIMIT 10;