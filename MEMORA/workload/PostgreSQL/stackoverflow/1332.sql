WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    up.PositivePostCount,
    rp.Title,
    rp.CreationDate,
    phc.ChangeCount,
    phc.LastChangeDate
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN 
    PostHistoryChanges phc ON rp.PostId = phc.PostId
WHERE 
    up.Reputation >= 1000
ORDER BY 
    up.PostCount DESC, up.Reputation DESC
LIMIT 10;