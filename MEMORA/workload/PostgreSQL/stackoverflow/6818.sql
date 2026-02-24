WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalComments,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalBountyAmount,
        DENSE_RANK() OVER (ORDER BY US.Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics US
    WHERE 
        US.TotalPosts > 0
)
SELECT 
    PU.UserId,
    PU.DisplayName,
    PU.Reputation,
    PU.TotalPosts,
    PU.TotalComments,
    PU.TotalQuestions,
    PU.TotalAnswers,
    PU.TotalBountyAmount,
    PU.ReputationRank
FROM 
    PopularUsers PU
WHERE 
    PU.ReputationRank <= 10
ORDER BY 
    PU.Reputation DESC;