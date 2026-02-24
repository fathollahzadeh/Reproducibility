
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 5
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.QuestionCount,
    US.AnswerCount,
    US.CommentCount,
    US.TotalBounties,
    PT.TagName,
    PT.PostCount
FROM UserStats US
LEFT JOIN PopularTags PT ON PT.PostCount > US.QuestionCount
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, PT.PostCount DESC
LIMIT 10
OFFSET 5;
