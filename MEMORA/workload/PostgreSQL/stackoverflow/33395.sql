WITH RECURSIVE UserReputation AS (
    SELECT U.Id, U.Reputation, U.CreationDate, 0 AS Level
    FROM Users U
    WHERE U.Reputation > 1000
    UNION ALL
    SELECT U.Id, U.Reputation, U.CreationDate, Level + 1
    FROM Users U
    INNER JOIN UserReputation UR ON U.Id = UR.Id
    WHERE U.Reputation > 1000
    AND Level < 3
), 
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
), 
PostStatistics AS (
    SELECT R.OwnerUserId, COUNT(R.Id) AS PostCount, 
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM RecentPosts R
    LEFT JOIN Votes V ON R.Id = V.PostId
    GROUP BY R.OwnerUserId
),
UserBadges AS (
    SELECT B.UserId, COUNT(B.Id) AS BadgeCount
    FROM Badges B
    WHERE B.Class = 1  
    GROUP BY B.UserId
)
SELECT U.DisplayName,
       U.Reputation,
       COALESCE(UB.BadgeCount, 0) AS GoldBadges,
       PS.PostCount,
       PS.UpVotes,
       PS.DownVotes,
       CASE 
         WHEN PS.PostCount > 0 THEN (PS.UpVotes::float / NULLIF(PS.PostCount, 0)) * 100
         ELSE 0
       END AS UpvotePercentage,
       CASE 
         WHEN PS.PostCount > 0 THEN PS.DownVotes * 1.0 / PS.PostCount * 100
         ELSE 0
       END AS DownvotePercentage,
       (SELECT STRING_AGG(DISTINCT PH.Comment, '; ') 
        FROM PostHistory PH 
        WHERE PH.UserId = U.Id AND PH.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year') AS RecentActivity
FROM Users U
LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE U.Reputation >= (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY U.Reputation DESC
LIMIT 10;