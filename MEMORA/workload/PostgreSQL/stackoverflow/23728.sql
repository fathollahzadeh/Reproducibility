WITH RecursivePostHistory AS (
    SELECT Ph.Id AS PostHistoryId,
           Ph.PostId,
           Ph.PostHistoryTypeId,
           Ph.CreationDate,
           Ph.UserId,
           Ph.Comment,
           ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM PostHistory Ph
    WHERE Ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentPostStats AS (
    SELECT P.Id AS PostId,
           P.OwnerUserId,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
           AVG(COALESCE(CAST(P.Score AS FLOAT), 0)) AS AvgScore,
           COUNT(DISTINCT C.Id) AS CommentCount,
           COUNT(DISTINCT PH.PostHistoryId) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS ClosureEvents,
           MAX(CASE WHEN PH.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasEdits
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN RecursivePostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months') 
      AND P.PostTypeId = 1
    GROUP BY P.Id, P.OwnerUserId
),
HighReputationUsers AS (
    SELECT U.Id AS UserId, 
           U.DisplayName,
           U.Reputation,
           DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    WHERE U.Reputation > 1000
),
PostSummaries AS (
    SELECT RPS.PostId,
           RPS.OwnerUserId,
           RPS.UpvoteCount,
           RPS.DownvoteCount,
           RPS.AvgScore,
           RPS.CommentCount,
           RPS.ClosureEvents,
           RPS.HasEdits,
           HRU.DisplayName AS HighReputationUser,
           HRU.Rank AS UserRank,
           COALESCE(PhIds.InPostLinks, 0) AS InPostLinksCount
    FROM RecentPostStats RPS
    LEFT JOIN HighReputationUsers HRU ON RPS.OwnerUserId = HRU.UserId
    LEFT JOIN (
        SELECT PL.PostId, COUNT(PL.RelatedPostId) AS InPostLinks
        FROM PostLinks PL
        GROUP BY PL.PostId
    ) AS PhIds ON RPS.PostId = PhIds.PostId
)
SELECT PS.PostId,
       PS.OwnerUserId,
       PS.UpvoteCount,
       PS.DownvoteCount,
       PS.AvgScore,
       PS.CommentCount,
       PS.ClosureEvents,
       PS.HasEdits,
       COALESCE(PS.HighReputationUser, 'None') AS HighReputationUser,
       CASE 
           WHEN PS.UserRank IS NULL THEN 'Non-High-Reputation-User'
           WHEN PS.UserRank <= 10 THEN 'Top 10 Users'
           WHEN PS.UserRank <= 50 THEN 'Top 50 Users'
           ELSE 'Below Top 50'
       END AS UserCategory,
       (CASE WHEN PS.HasEdits = 1 THEN 'Edited' ELSE 'Not Edited' END) AS EditStatus,
       cast('2024-10-01 12:34:56' as timestamp) AS QueryTimestamp
FROM PostSummaries PS
WHERE PS.AvgScore IS NOT NULL
ORDER BY PS.AvgScore DESC, PS.CommentCount DESC
LIMIT 100
OFFSET (SELECT FLOOR(RANDOM() * COUNT(*)) FROM Posts WHERE PostTypeId = 1);