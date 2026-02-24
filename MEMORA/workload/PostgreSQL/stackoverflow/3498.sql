
WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, U.CreationDate,
           RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostSummary AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.Score, P.CreationDate,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    GROUP BY P.Id, P.OwnerUserId, P.Score, P.CreationDate
),
TopPosts AS (
    SELECT PS.PostId, PS.OwnerUserId, PS.Score, PS.CommentCount,
           ROW_NUMBER() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.Score DESC) AS PostRank
    FROM PostSummary PS
)
SELECT U.DisplayName, U.Reputation, U.CreationDate,
       T.Score, T.CommentCount,
       COALESCE((SELECT SUM(B.Class) FROM Badges B WHERE B.UserId = U.UserId), 0) AS TotalBadges,
       CASE
           WHEN T.PostRank = 1 THEN 'Top Post for User'
           ELSE 'Other Post'
       END AS PostCategory
FROM UserReputation U
LEFT JOIN TopPosts T ON U.UserId = T.OwnerUserId AND T.PostRank <= 5
WHERE U.Reputation > 100
ORDER BY U.Reputation DESC, T.Score DESC;
