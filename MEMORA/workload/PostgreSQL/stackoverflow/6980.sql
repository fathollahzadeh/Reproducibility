
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
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
        TotalBountyAmount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalQuestions,
    U.TotalBountyAmount,
    T.Name AS MostVotedPostType,
    COUNT(P2.Id) AS RelatedPostsCount
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes T ON P.PostTypeId = T.Id
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Posts P2 ON PL.RelatedPostId = P2.Id
WHERE 
    U.Rank <= 10
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.TotalPosts, U.TotalAnswers, U.TotalQuestions, U.TotalBountyAmount, T.Name
ORDER BY 
    U.Reputation DESC;
