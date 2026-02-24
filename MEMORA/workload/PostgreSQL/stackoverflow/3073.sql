WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UP.TotalViews,
    UP.AverageScore,
    (UP.GoldBadges * 3 + UP.SilverBadges * 2 + UP.BronzeBadges * 1) AS BadgeScore
FROM 
    UserPerformance UP
WHERE 
    (UP.TotalPosts > 10 OR UP.GoldBadges > 0)
ORDER BY 
    BadgeScore DESC, 
    UP.TotalViews DESC;
