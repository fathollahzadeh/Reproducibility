WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.ViewCount,
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation,
           COALESCE(UB.BadgeCount, 0) AS BadgeCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, UB.BadgeCount
)
SELECT TU.DisplayName, TU.Reputation, TU.BadgeCount,
       R.Title AS RecentPostTitle, R.ViewCount AS RecentPostViews,
       CASE 
           WHEN R.RecentRank = 1 THEN 'Most Recent'
           ELSE 'Not Most Recent'
       END AS RecentPostStatus
FROM TopUsers TU
LEFT JOIN RecentPosts R ON TU.Id = R.OwnerUserId
WHERE TU.UserRank <= 10 
ORDER BY TU.Reputation DESC, RecentPostViews DESC NULLS LAST;