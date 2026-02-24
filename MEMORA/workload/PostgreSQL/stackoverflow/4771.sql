WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 
    GROUP BY u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY ph.PostId
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgScore
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    u.Id AS OwnerUserId,
    u.DisplayName,
    ur.Reputation,
    ur.TotalBounties,
    COALESCE(phd.EditCount, 0) AS EditCount,
    phd.LastEditedDate,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.AvgScore, 0) AS AvgScore,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationLevel
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PostHistoryDetails phd ON rp.Id = phd.PostId
LEFT JOIN CommentStats cs ON rp.Id = cs.PostId
WHERE rp.rn = 1 
ORDER BY rp.CreationDate DESC
LIMIT 50;