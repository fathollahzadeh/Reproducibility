
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS BadgePoints,
        MAX(u.Reputation) AS UserReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.PostHistoryTypeId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    u.DisplayName AS Owner,
    ur.UserReputation,
    ur.BadgePoints,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN ur.UserReputation >= 5000 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.rn = 1 
    AND ur.BadgePoints > 0
ORDER BY 
    ur.UserReputation DESC, 
    rp.ViewCount DESC;
