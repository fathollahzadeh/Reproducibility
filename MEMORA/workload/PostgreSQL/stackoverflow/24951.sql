WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
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
        SUM(CASE WHEN p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
MostActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        ur.RecentPostCount,
        RANK() OVER (ORDER BY ur.RecentPostCount DESC, ur.Reputation DESC) AS ActiveRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation IS NOT NULL AND ur.Reputation > 0
)
SELECT 
    rau.UserId,
    u.DisplayName,
    rau.Reputation,
    rau.PostCount,
    rau.RecentPostCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    STRING_AGG(ph.Comment, '; ') FILTER (WHERE ph.Comment IS NOT NULL) AS PostComments,
    COUNT(DISTINCT CASE WHEN pht.Name = 'Post Closed' THEN ph.Id END) AS ClosedPosts
FROM 
    MostActiveUsers rau
JOIN 
    Users u ON rau.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = rau.UserId AND rp.Rank <= 5
LEFT JOIN 
    PostHistory ph ON ph.PostId = rp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    rau.ActiveRank <= 10
GROUP BY 
    rau.UserId, u.DisplayName, rau.Reputation, rau.PostCount, rau.RecentPostCount, rp.PostId, rp.Title, rp.Score, rp.ViewCount
ORDER BY 
    rau.RecentPostCount DESC, rau.Reputation DESC, rp.Score DESC;