
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTagUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(T.Tag) AS TagCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    CROSS JOIN LATERAL (SELECT unnest(string_to_array(P.Tags, '><')) AS Tag) T
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(T.Tag) > 10
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        RANK() OVER (ORDER BY P.Score DESC, P.AnswerCount DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBounty,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    T.TagCount,
    PP.Title,
    PP.Score,
    PP.AnswerCount
FROM UserStats US
LEFT JOIN TopTagUsers T ON US.UserId = T.UserId
LEFT JOIN PopularPosts PP ON PP.PostId IN (
    SELECT R.PostId
    FROM PopularPosts R
    WHERE R.PostRank <= 10
)
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, PP.Score DESC
FETCH FIRST 10 ROWS ONLY;
