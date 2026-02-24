
WITH UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TagPerformance AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPostsTagged,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswersTagged,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestionsTagged
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.Reputation,
    UP.TotalPosts,
    UP.TotalQuestions,
    UP.TotalAnswers,
    UP.TotalUpvotes,
    UP.TotalDownvotes,
    TP.TagName,
    TP.TotalPostsTagged,
    TP.TotalAnswersTagged,
    TP.TotalQuestionsTagged
FROM UserPerformance UP
LEFT JOIN TagPerformance TP ON UP.TotalPosts > 0
ORDER BY UP.Reputation DESC, UP.TotalPosts DESC, TP.TotalPostsTagged DESC
LIMIT 10;
