
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
RecentPosts AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.Title, P.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserScores AS (
    SELECT U.Id AS UserId, U.DisplayName, COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty, COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT U.UserId, U.DisplayName, B.BadgeCount, U.TotalScore, U.TotalBounty,
           ROW_NUMBER() OVER (ORDER BY U.TotalScore DESC, U.TotalBounty DESC) AS Rank
    FROM UserScores U
    JOIN UserBadges B ON U.UserId = B.UserId
)
SELECT T.UserId, T.DisplayName, T.BadgeCount, T.TotalScore, T.TotalBounty, 
       (SELECT COUNT(*) FROM RecentPosts RP WHERE RP.OwnerUserId = T.UserId) AS RecentPostCount,
       CASE WHEN T.BadgeCount > 5 THEN 'High Achiever' ELSE 'Needs Improvement' END AS PerformanceLabel
FROM TopUsers T
WHERE T.Rank <= 10
ORDER BY T.TotalScore DESC, T.TotalBounty DESC;
