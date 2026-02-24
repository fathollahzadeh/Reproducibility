WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalComments,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    TU.UserId,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.Upvotes,
    TU.Downvotes,
    (TU.Upvotes - TU.Downvotes) AS NetVotes,
    CASE 
        WHEN TU.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN TU.ReputationRank BETWEEN 11 AND 50 THEN 'Valuable Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    TopUsers TU
WHERE 
    TU.TotalPosts > 0
ORDER BY 
    TU.Reputation DESC, TU.TotalPosts DESC
LIMIT 100;
