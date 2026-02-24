
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(US.BadgeCount, 0) AS BadgeCount,
        COALESCE(US.GoldBadges, 0) AS GoldBadges,
        COALESCE(US.SilverBadges, 0) AS SilverBadges,
        COALESCE(US.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalScore, 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts US ON U.Id = US.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.TotalPosts,
    UA.Questions,
    UA.Answers,
    UA.TotalViews,
    UA.TotalScore,
    ROUND(COALESCE(NULLIF(UA.TotalViews, 0), 1) / NULLIF(UA.TotalPosts, 0), 2) AS AvgViewsPerPost,
    ROUND(COALESCE(NULLIF(UA.TotalScore, 0), 1) / NULLIF(UA.TotalPosts, 0), 2) AS AvgScorePerPost
FROM 
    UserActivity UA
WHERE 
    UA.TotalPosts > 0
ORDER BY 
    UA.TotalScore DESC, UA.BadgeCount DESC
LIMIT 10;
