
WITH UserAggregate AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY Upvotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserAggregate
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers,
    T.Upvotes,
    T.Downvotes,
    CASE 
        WHEN T.UpvoteRank <= 10 THEN 'Top Upvoted'
        ELSE 'Moderate Upvoted'
    END AS UpvoteCategory,
    CASE 
        WHEN T.PostRank <= 10 THEN 'Top Contributor'
        ELSE 'Moderate Contributor'
    END AS ContributionCategory,
    (SELECT STRING_AGG(P.Title, '; ') 
     FROM Posts P 
     WHERE P.OwnerUserId = T.UserId) AS PostTitles
FROM 
    TopUsers T
WHERE 
    T.TotalPosts > 0 
ORDER BY 
    T.Upvotes DESC, T.TotalPosts DESC;
