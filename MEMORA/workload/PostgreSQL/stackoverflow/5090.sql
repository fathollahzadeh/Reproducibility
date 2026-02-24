WITH UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
), 
PostActivity AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.Score) AS TotalScore, AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, ur.BadgeCount, pa.PostCount, pa.TotalScore, pa.AvgViewCount
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.UserId
    JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    WHERE u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' AND u.Reputation > 1000
)
SELECT au.UserId, au.DisplayName, au.Reputation, au.BadgeCount, au.PostCount, au.TotalScore, au.AvgViewCount, 
       CASE 
           WHEN au.Reputation > 5000 THEN 'Expert'
           WHEN au.Reputation > 1000 THEN 'Active'
           ELSE 'Newcomer'
       END AS UserLevel
FROM ActiveUsers au
ORDER BY au.Reputation DESC, au.PostCount DESC
LIMIT 10;