WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT
    UPS.DisplayName,
    UPS.TotalBadges,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.TotalScore,
    UPS.AvgViewCount,
    CASE 
        WHEN UPS.TotalPosts > 50 THEN 'High Activity' 
        WHEN UPS.TotalPosts > 20 THEN 'Moderate Activity'
        ELSE 'Low Activity' 
    END AS ActivityLevel
FROM 
    UserPostStats UPS
WHERE 
    UPS.TotalBadges > 0
ORDER BY 
    UPS.TotalScore DESC,
    UPS.TotalPosts DESC
LIMIT 10;
