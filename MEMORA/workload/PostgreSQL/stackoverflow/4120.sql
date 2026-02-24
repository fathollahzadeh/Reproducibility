
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalBounty,
    ur.PostCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    cp.CloseCount
FROM UserReputation ur
JOIN RankedPosts rp ON ur.UserId = rp.OwnerUserId
LEFT JOIN ClosedPosts cp ON rp.Id = cp.PostId
WHERE ur.Reputation > 1000 
    AND rp.PostRank <= 3
ORDER BY ur.Reputation DESC, rp.Score DESC;
