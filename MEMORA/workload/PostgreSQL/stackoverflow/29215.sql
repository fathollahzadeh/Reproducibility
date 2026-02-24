WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN B.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostInteractionStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBS.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PIS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PIS.TotalComments, 0) AS TotalComments,
        COALESCE(PIS.TotalVotes, 0) AS TotalVotes,
        COALESCE(PIS.TotalViews, 0) AS TotalViews,
        COALESCE(PIS.TotalScore, 0) AS TotalScore
    FROM Users U
    LEFT JOIN UserBadgeStats UBS ON U.Id = UBS.UserId
    LEFT JOIN PostInteractionStats PIS ON U.Id = PIS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalViews,
    TotalScore,
    (TotalScore * 1.0 / NULLIF(TotalPosts, 0)) AS ScorePerPost,
    (TotalViews * 1.0 / NULLIF(TotalPosts, 0)) AS ViewsPerPost
FROM UserEngagement
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 10;
