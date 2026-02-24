WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationTier
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    p.Title,
    p.Score,
    p.CreationDate,
    ur.Reputation,
    ur.ReputationTier,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(cp.CloseCount, 0) AS ClosedCount,
    CASE 
        WHEN cp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM Posts p
JOIN UserReputation ur ON p.OwnerUserId = ur.Id
LEFT JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
  AND ur.ReputationTier IN ('High', 'Medium')
  AND p.ViewCount > 0
  AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 3
ORDER BY p.CreationDate DESC, p.Score DESC
LIMIT 100;