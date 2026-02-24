WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS UserRank
    FROM 
        UserStats
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBounty,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments C 
     WHERE 
        C.UserId = TU.UserId) AS TotalComments,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 1) AS GoldBadges,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 2) AS SilverBadges,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId AND B.Class = 3) AS BronzeBadges
FROM 
    TopUsers TU
ORDER BY 
    TU.TotalPosts DESC, TU.Reputation DESC;
