
WITH RankedUsers AS (
    SELECT Id, DisplayName, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
ActivePosts AS (
    SELECT P.Id AS PostId, P.Title, P.OwnerUserId, 
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
           MAX(P.LastActivityDate) AS LastActivity
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
PostDetails AS (
    SELECT AP.PostId, AP.Title, U.DisplayName AS OwnerDisplayName, 
           RU.ReputationRank, AP.CommentCount, AP.VoteCount, AP.LastActivity
    FROM ActivePosts AP
    JOIN Users U ON AP.OwnerUserId = U.Id
    JOIN RankedUsers RU ON U.Id = RU.Id
    WHERE AP.CommentCount > 0 OR AP.VoteCount > 0
),
TopPosts AS (
    SELECT *, RANK() OVER (PARTITION BY ReputationRank ORDER BY CommentCount DESC, VoteCount DESC) AS RankWithinGroup
    FROM PostDetails
)
SELECT PostId, Title, OwnerDisplayName, ReputationRank, CommentCount, VoteCount, LastActivity
FROM TopPosts
WHERE RankWithinGroup <= 5
ORDER BY ReputationRank, RankWithinGroup;
