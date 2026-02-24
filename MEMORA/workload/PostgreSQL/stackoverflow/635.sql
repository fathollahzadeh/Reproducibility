WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PopularPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Score,
           P.ViewCount,
           P.AnswerCount,
           P.OwnerUserId,
           RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
      AND P.Score > 0
),
PostVoteCounts AS (
    SELECT V.PostId,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Votes V
    GROUP BY V.PostId
),
CommentsSummary AS (
    SELECT C.PostId,
           COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
)
SELECT U.DisplayName,
       U.Reputation,
       U.ReputationRank,
       P.Title,
       P.PopularityRank,
       COALESCE(PV.UpvoteCount, 0) AS TotalUpvotes,
       COALESCE(PV.DownvoteCount, 0) AS TotalDownvotes,
       COALESCE(CS.CommentCount, 0) AS TotalComments,
       P.CreationDate,
       P.Score
FROM UserReputation U
JOIN PopularPosts P ON U.UserId = P.OwnerUserId
LEFT JOIN PostVoteCounts PV ON P.PostId = PV.PostId
LEFT JOIN CommentsSummary CS ON P.PostId = CS.PostId
WHERE U.Reputation > 1000
  AND (P.AnswerCount > 5 OR P.Score > 10)
ORDER BY U.Reputation DESC, P.PopularityRank;