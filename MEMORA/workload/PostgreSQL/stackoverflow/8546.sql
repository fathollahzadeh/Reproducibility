WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalClosedPosts,
        BC.TotalBadges,
        BC.GoldBadges,
        BC.SilverBadges,
        BC.BronzeBadges
    FROM 
        UserStats US
    LEFT JOIN 
        BadgeCounts BC ON US.UserId = BC.UserId
    ORDER BY 
        US.Reputation DESC, US.TotalPosts DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalClosedPosts,
    TU.TotalBadges,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = TU.UserId AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR') AS PostsLastYear
FROM 
    TopUsers TU;