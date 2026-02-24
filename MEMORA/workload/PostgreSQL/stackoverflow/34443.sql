
WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS Level
    FROM Tags
    WHERE WikiPostId IS NOT NULL
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, th.Level + 1
    FROM Tags t
    INNER JOIN TagHierarchy th ON t.ExcerptPostId = th.Id
),
UserStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COALESCE(SUM(P.AnswerCount), 0) AS TotalAnswers,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentEdits AS (
    SELECT PH.PostId,
           PH.UserId,
           PH.CreationDate,
           PH.Comment,
           PH.Text
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5)  
      AND PH.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
),
TopUsers AS (
    SELECT UserId, 
           COUNT(*) AS EditCount,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS Rank
    FROM RecentEdits
    GROUP BY UserId
    HAVING COUNT(*) > 1
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    U.Upvotes,
    U.Downvotes,
    U.TotalAnswers,
    TH.TagName AS TopTag,
    TH.Count AS TagCount,
    RU.EditCount,
    RU.Rank
FROM UserStats U
LEFT JOIN Tags T ON U.UserId = T.ExcerptPostId
LEFT JOIN TagHierarchy TH ON T.Id = TH.Id
JOIN TopUsers RU ON RU.UserId = U.UserId
WHERE U.TotalAnswers > 5
  AND U.Reputation > 100
  AND (TH.Count IS NULL OR TH.Count > 10)
ORDER BY U.Reputation DESC, RU.EditCount DESC
LIMIT 50;
