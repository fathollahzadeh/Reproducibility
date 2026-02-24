
WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, CreationDate, UpVotes, DownVotes, (UpVotes - DownVotes) AS NetVotes
    FROM Users
    WHERE Reputation > 0
    UNION ALL
    SELECT u.Id, u.Reputation, u.CreationDate, u.UpVotes, u.DownVotes, (u.UpVotes - u.DownVotes) AS NetVotes
    FROM Users u
    INNER JOIN UserReputationCTE ur ON ur.Id = u.Id
    WHERE u.Reputation > ur.Reputation
),
RecentPostCTE AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId,
           DENSE_RANK() OVER (PARTITION BY p.ParentId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 weeks'
),
PostHistoryCount AS (
    SELECT PostId, COUNT(*) AS HistoryCount
    FROM PostHistory
    WHERE PostHistoryTypeId IN (10, 12, 6) 
    GROUP BY PostId
),
UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(rp.Score, 0) AS PostScore,
    COALESCE(ph.HistoryCount, 0) AS PostHistoryChanges,
    COUNT(DISTINCT rp.Id) AS RecentPostsCount,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalPostScore
FROM Users u
LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN RecentPostCTE rp ON u.Id = rp.OwnerUserId
LEFT JOIN PostHistoryCount ph ON rp.Id = ph.PostId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users) 
GROUP BY u.Id, u.DisplayName, u.Reputation, ub.BadgeCount, rp.Score, ph.HistoryCount
ORDER BY UserName
LIMIT 100;
