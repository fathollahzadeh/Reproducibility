WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS ReputationRank
    FROM 
        UserReputation
),
TopTags AS (
    SELECT 
        Tags.TagName,
        COUNT(P.Id) AS PostsCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(P.Id) > 10
    ORDER BY 
        PostsCount DESC
    LIMIT 5
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    T.TagName,
    T.PostsCount,
    T.TotalViews,
    T.AverageScore
FROM 
    TopUsers U
JOIN 
    TopTags T ON T.PostsCount > 10
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.TotalUpVotes DESC, U.TotalPosts DESC;
