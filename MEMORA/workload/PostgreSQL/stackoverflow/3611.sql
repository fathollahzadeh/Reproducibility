WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation > 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11, 12) THEN ph.CreationDate END) AS LastReopenDate,
        COUNT(ph.Id) AS EditCount
    FROM PostHistory ph
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY ph.PostId
)
SELECT 
    p.Title,
    ur.ReputationLevel,
    pm.CommentCount,
    pm.TotalBounty,
    phd.LastCloseDate,
    phd.LastReopenDate,
    phd.EditCount
FROM Posts p
JOIN UserReputation ur ON p.OwnerUserId = ur.Id
JOIN PostMetrics pm ON p.Id = pm.PostId
LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
WHERE pm.CommentCount > 5
AND (phd.LastCloseDate IS NULL OR phd.LastReopenDate > phd.LastCloseDate)
ORDER BY ur.ReputationLevel DESC, pm.TotalBounty DESC, pm.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;