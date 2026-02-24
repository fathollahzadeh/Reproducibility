
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS RankReputation,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankPosts
    FROM 
        UserStatistics
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Users U
    JOIN 
        Posts p ON U.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalQuestions,
    TU.TotalBounties,
    RA.Title AS RecentPostTitle,
    RA.CreationDate AS RecentPostDate
FROM 
    TopUsers TU
LEFT JOIN 
    RecentActivity RA ON TU.UserId = RA.UserId AND RA.RecentPostRank = 1
WHERE 
    TU.RankReputation <= 10 OR TU.RankPosts <= 10
ORDER BY 
    TU.RankReputation, TU.RankPosts
LIMIT 50;
