
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(V.BountyAmount) AS TotalBounties,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsContributed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        (SELECT UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS TagName, P.Id AS PostId FROM Posts P) AS T ON P.Id = T.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.TotalPosts,
    U.TotalComments,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalTagWikis,
    U.TotalBounties,
    U.TagsContributed,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    DENSE_RANK() OVER (ORDER BY U.TotalPosts DESC) AS PostsRank
FROM 
    UserStats U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, U.TotalPosts DESC
LIMIT 10;
