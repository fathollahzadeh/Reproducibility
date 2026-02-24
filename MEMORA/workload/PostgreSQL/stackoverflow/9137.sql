
WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ActivityStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalTagWikis, 0) AS TotalTagWikis,
        COALESCE(PS.PositivePosts, 0) AS PositivePosts,
        CASE 
            WHEN COALESCE(UB.TotalBadges, 0) > 10 THEN 'Active Contributor'
            WHEN COALESCE(PS.TotalPosts, 0) > 100 THEN 'Veteran' 
            ELSE 'New Contributor' 
        END AS ContributorStatus
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId, 
    DisplayName, 
    TotalBadges, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalTagWikis, 
    PositivePosts, 
    ContributorStatus
FROM 
    ActivityStats
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalPosts DESC, 
    TotalBadges DESC
LIMIT 50;
