
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS TotalBadges, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalBadges,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.AvgScore,
    CASE 
        WHEN U.TotalPosts > 50 AND U.TotalBadges > 5 THEN 'Top Contributor'
        WHEN U.TotalPosts > 20 AND U.TotalBadges > 0 THEN 'Moderate Contributor'
        ELSE 'Novice Contributor'
    END AS ContributorLevel,
    RANK() OVER (ORDER BY U.AvgScore DESC) AS ScoreRank
FROM 
    UserPostBadgeStats U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    ContributorLevel DESC, AvgScore DESC;
