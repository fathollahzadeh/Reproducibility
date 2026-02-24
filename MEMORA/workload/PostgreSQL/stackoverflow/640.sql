WITH UserStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           MAX(P.CreationDate) AS LastPostDate,
           MIN(P.CreationDate) AS FirstPostDate,
           (SELECT COUNT(*) FROM Votes V 
            WHERE V.UserId = U.Id AND V.VoteTypeId IN (2, 3)) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT T.TagName,
           COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
RecentPosts AS (
    SELECT P.Id,
           P.Title,
           P.CreationDate,
           U.DisplayName AS Author,
           P.Score,
           RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT U.UserId,
       U.DisplayName,
       U.Reputation,
       U.PostCount,
       U.QuestionCount,
       U.AnswerCount,
       U.LastPostDate,
       U.FirstPostDate,
       U.TotalVotes,
       T.TagName,
       RP.Title AS RecentPostTitle,
       RP.CreationDate AS RecentPostDate,
       RP.Author,
       RP.Score
FROM UserStats U
LEFT JOIN PopularTags T ON U.PostCount > 5
LEFT JOIN RecentPosts RP ON RP.Rank = 1
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, U.PostCount DESC NULLS LAST
LIMIT 100;