WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score,
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCount UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
)
SELECT TU.DisplayName, TU.Reputation, TU.BadgeCount, RP.Title AS RecentPostTitle, RP.CreationDate
FROM TopUsers TU
LEFT JOIN RecentPosts RP ON TU.Id = RP.OwnerUserId
WHERE RP.PostRank = 1 OR RP.PostRank IS NULL
ORDER BY TU.Reputation DESC, TU.BadgeCount DESC
LIMIT 10;