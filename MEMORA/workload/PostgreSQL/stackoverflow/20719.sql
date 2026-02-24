WITH UserBadgeSummary AS (
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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        U.Reputation
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
),
BadgePerformance AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalBadges,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        UP.TotalPosts,
        UP.Reputation,
        RANK() OVER (ORDER BY UP.Reputation DESC) AS ReputationRank
    FROM 
        UserBadgeSummary U
    JOIN 
        UserPerformance UP ON U.UserId = UP.UserId
),
ReputationCategories AS (
    SELECT
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
    GROUP BY 
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END
)
SELECT 
    BP.DisplayName,
    BP.TotalBadges,
    BP.GoldBadges,
    BP.SilverBadges,
    BP.BronzeBadges,
    BP.TotalPosts,
    BP.Reputation,
    RP.ReputationCategory,
    RP.AvgReputation,
    CASE 
        WHEN BP.TotalPosts > 10 THEN 'Active User'
        ELSE 'Less Active User'
    END AS UserActivityLevel
FROM 
    BadgePerformance BP
JOIN 
    ReputationCategories RP ON BP.Reputation BETWEEN RP.AvgReputation - 500 AND RP.AvgReputation + 500
WHERE 
    (BP.GoldBadges > 0 OR BP.SilverBadges > 0) 
    AND BP.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    BP.Reputation DESC, 
    BP.TotalPosts DESC;

