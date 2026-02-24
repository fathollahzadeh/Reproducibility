
WITH RECURSIVE RecursiveCTE AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.Score,
           P.CreationDate,
           0 AS Level,
           P.OwnerUserId
    FROM Posts P
    WHERE P.PostTypeId = 1 
    UNION ALL
    SELECT A.Id AS PostId,
           A.Title,
           A.Score,
           A.CreationDate,
           R.Level + 1,
           A.OwnerUserId
    FROM Posts A
    INNER JOIN RecursiveCTE R ON A.ParentId = R.PostId
    WHERE A.PostTypeId = 2 
),
PostScores AS (
    SELECT P.Id,
           P.Title,
           P.OwnerUserId,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           P.Score AS CurrentScore,
           (COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) - COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END)) AS NetScore,
           R.Level
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN RecursiveCTE R ON P.Id = R.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.Score, R.Level
),
UserBadges AS (
    SELECT U.Id AS UserId,
           COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
FinalOutput AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           PS.Title,
           PS.CurrentScore,
           PS.NetScore,
           PS.CommentCount,
           UB.BadgeCount,
           PS.Level
    FROM PostScores PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    JOIN UserBadges UB ON U.Id = UB.UserId
)
SELECT UserId,
       DisplayName,
       Title,
       CurrentScore,
       NetScore,
       CommentCount,
       BadgeCount,
       Level
FROM FinalOutput
WHERE Level = 0 
ORDER BY NetScore DESC, CurrentScore DESC
LIMIT 100;
