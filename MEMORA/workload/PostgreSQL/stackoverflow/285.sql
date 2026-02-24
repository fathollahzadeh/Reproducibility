
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.BadgeCount,
    COALESCE(SUM(CASE WHEN ph.Comment IS NOT NULL AND ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
    COALESCE(SUM(CASE WHEN ph.Comment IS NOT NULL AND ph.PostHistoryTypeId IN (11, 12) THEN 1 ELSE 0 END), 0) AS ReopenOrDeleteCount,
    CASE 
        WHEN t.PostCount > 0 THEN ROUND(CAST(t.Reputation AS FLOAT) / t.PostCount, 2)
        ELSE 0
    END AS ReputationPerPost
FROM TopUsers t
LEFT JOIN PostHistory ph ON t.UserId = ph.UserId
WHERE t.ReputationRank <= 10
GROUP BY t.DisplayName, t.Reputation, t.PostCount, t.BadgeCount
ORDER BY t.Reputation DESC;
