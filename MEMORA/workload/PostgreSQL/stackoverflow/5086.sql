
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
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
        TotalUpvotes,
        TotalDownvotes,
        ReputationRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5 
)
SELECT 
    TU.UserId,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    TU.ReputationRank,
    STRING_AGG(DISTINCT T.TagName, ', ') AS PopularTags
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE
GROUP BY 
    TU.UserId, TU.Reputation, TU.TotalPosts, TU.TotalComments, TU.TotalUpvotes, TU.TotalDownvotes, TU.ReputationRank
ORDER BY 
    TU.Reputation DESC;
