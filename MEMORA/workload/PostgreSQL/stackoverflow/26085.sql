WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikiPosts,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
),
CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalWikiPosts,
        US.TotalComments,
        TS.TagName,
        TS.PostCount AS TagPostCount,
        TS.QuestionCount AS TagQuestionCount,
        TS.AnswerCount AS TagAnswerCount
    FROM UserStats US
    LEFT JOIN TagStats TS ON US.TotalPosts > 0
    ORDER BY US.Reputation DESC, US.TotalPosts DESC
)

SELECT 
    CS.DisplayName,
    CS.Reputation,
    CS.TotalPosts,
    CS.TotalQuestions,
    CS.TotalAnswers,
    CS.TotalWikiPosts,
    CS.TotalComments,
    COALESCE(CS.TagName, 'No Tags') AS TagName,
    COALESCE(CS.TagPostCount, 0) AS TagPostCount,
    COALESCE(CS.TagQuestionCount, 0) AS TagQuestionCount,
    COALESCE(CS.TagAnswerCount, 0) AS TagAnswerCount
FROM CombinedStats CS
WHERE CS.TotalPosts > 5 
ORDER BY CS.Reputation DESC, CS.TotalPosts DESC
LIMIT 50;