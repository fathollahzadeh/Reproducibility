WITH UserBadges AS (
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
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserBenchmarks AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS TotalQuestions,
        COALESCE(PS.Answers, 0) AS TotalAnswers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AverageViews, 0) AS AverageViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
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
    TotalScore,
    AverageViews,
    CASE 
        WHEN TotalBadges >= 5 AND TotalPosts >= 10 THEN 'Active Contributor'
        WHEN TotalBadges >= 3 AND TotalPosts < 10 THEN 'Emerging Contributor'
        ELSE 'New User'
    END AS UserType
FROM 
    UserBenchmarks
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
