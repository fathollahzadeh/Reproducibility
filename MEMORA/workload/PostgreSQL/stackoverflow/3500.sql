WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UA.*,
        DENSE_RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity UA
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.QuestionCount,
    RU.AnswerCount,
    COALESCE(RU.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN RU.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN RU.ReputationRank <= 50 THEN 'Active Contributor'
        ELSE 'Novice Contributor'
    END AS ContributionLevel
FROM 
    RankedUsers RU
WHERE 
    RU.QuestionCount > 5
    AND RU.AnswerCount > 10
ORDER BY 
    RU.Reputation DESC
LIMIT 20;