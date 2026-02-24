
WITH RecursivePostHistory AS (
    SELECT Ph.PostId,
           Ph.UserId,
           Ph.CreationDate,
           Ph.PostHistoryTypeId,
           HNT.Name AS HistoryTypeName,
           ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM PostHistory Ph
    JOIN PostHistoryTypes HNT ON Ph.PostHistoryTypeId = HNT.Id
),
CommentCounts AS (
    SELECT PostId,
           COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
),
UserStats AS (
    SELECT U.Id AS UserId,
           U.Reputation,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostsWithBadges AS (
    SELECT P.Id AS PostId,
           P.OwnerUserId,
           COUNT(B.Id) AS BadgeCount,
           P.Title,
           P.Score
    FROM Posts P
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    GROUP BY P.Id, P.OwnerUserId, P.Title, P.Score
)
SELECT PWB.PostId,
       PWB.Title,
       PWB.Score,
       COALESCE(CC.TotalComments, 0) AS TotalComments,
       RPH.UserId AS LastEditorUserId,
       RPH.HistoryTypeName AS LastActionType,
       RPH.CreationDate AS LastActionDate,
       U.Reputation,
       U.UpVotes,
       U.DownVotes,
       CASE 
           WHEN PWB.Score > 0 THEN 'Popular'
           ELSE 'Less Popular'
       END AS Popularity
FROM PostsWithBadges PWB
LEFT JOIN CommentCounts CC ON PWB.PostId = CC.PostId
LEFT JOIN RecursivePostHistory RPH ON PWB.PostId = RPH.PostId AND RPH.rn = 1
JOIN UserStats U ON PWB.OwnerUserId = U.UserId
WHERE PWB.Score IS NOT NULL
ORDER BY PWB.Score DESC, TotalComments DESC
FETCH FIRST 100 ROWS ONLY;
