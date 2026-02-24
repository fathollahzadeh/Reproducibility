WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
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
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AvgScore
    FROM 
        UserReputation UR
    JOIN 
        PostStats PS ON UR.UserId = PS.OwnerUserId
    WHERE 
        UR.ReputationRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    COALESCE(TU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TU.AvgScore, 0) AS AvgScore,
    CASE 
        WHEN TU.TotalPosts > 50 THEN 'Active Contributor'
        WHEN TU.TotalPosts BETWEEN 20 AND 50 THEN 'Regular Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId AND B.Class = 1  
WHERE 
    B.Id IS NULL  
ORDER BY 
    TU.Reputation DESC, TU.TotalPosts DESC;