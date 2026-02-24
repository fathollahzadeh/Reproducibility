
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
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    COALESCE(UB.TotalBadges, 0) AS TotalBadges,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.Questions, 0) AS TotalQuestions,
    COALESCE(PS.Answers, 0) AS TotalAnswers,
    COALESCE(PS.AverageScore, 0) AS AveragePostScore,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate
FROM 
    Users U
LEFT JOIN 
    UserBadgeStats UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentPostRank = 1
WHERE 
    COALESCE(UB.TotalBadges, 0) > 0 OR 
    COALESCE(PS.TotalPosts, 0) > 0
ORDER BY 
    COALESCE(UB.TotalBadges, 0) DESC, 
    COALESCE(PS.TotalPosts, 0) DESC;
