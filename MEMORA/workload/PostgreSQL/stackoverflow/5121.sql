
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
),
HighActivityUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.AnswerCount,
        U.QuestionCount,
        U.CommentCount,
        U.BadgeCount
    FROM TopUsers U
    WHERE U.ReputationRank <= 100
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.PostCount AS TotalPosts,
    U.AnswerCount AS TotalAnswers,
    U.QuestionCount AS TotalQuestions,
    U.CommentCount AS TotalComments,
    U.BadgeCount AS TotalBadges,
    T.TagName AS PopularTag,
    T.PostCount AS PostsTagged,
    T.QuestionCount AS QuestionsTagged,
    T.AnswerCount AS AnswersTagged
FROM HighActivityUsers U
CROSS JOIN PopularTags T
ORDER BY U.Reputation DESC, T.PostCount DESC;
