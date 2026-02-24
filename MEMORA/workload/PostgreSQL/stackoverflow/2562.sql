WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalBounty, 
        TotalUpvotes, 
        TotalDownvotes, 
        TotalPosts,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalBounty DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalBounty,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    TU.TotalPosts,
    TU.TotalComments,
    CASE 
        WHEN TU.Reputation > 10000 THEN 'High Reputation'
        WHEN TU.Reputation BETWEEN 5000 AND 10000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN TU.TotalPosts > 50 THEN 'Active User'
        ELSE 'Less Active User'
    END AS ActivityLevel
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, TU.TotalBounty DESC;
