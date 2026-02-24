WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
HighReputationUsers AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.PostCount,
        us.TotalScore
    FROM 
        UserScores us
    WHERE 
        us.Reputation > (SELECT AVG(Reputation) FROM Users)
),
TopViewCountPosts AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        rp.OwnerUserId,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS rn
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.ViewCount > 100
)
SELECT 
    COUNT(DISTINCT h.UserId) AS UniqueHighRepUsers,
    SUM(h.Reputation) AS TotalReputation,
    AVG(t.ViewCount) AS AverageViewCount
FROM 
    HighReputationUsers h
LEFT JOIN 
    TopViewCountPosts t ON h.UserId = t.OwnerUserId
WHERE 
    t.rn <= 5
GROUP BY 
    t.OwnerUserId
HAVING 
    COUNT(t.Title) > 0
ORDER BY 
    TotalReputation DESC;