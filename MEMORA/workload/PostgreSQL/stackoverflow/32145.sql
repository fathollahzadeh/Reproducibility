WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5 
),
HighlightedBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    mu.PostCount,
    mu.TotalScore,
    bh.BadgeNames,
    phg.LastEditDate,
    phg.CloseCount,
    pp.Title AS MostRecentPostTitle,
    pp.ViewCount
FROM 
    Users u
LEFT JOIN 
    MostActiveUsers mu ON u.Id = mu.UserId
LEFT JOIN 
    HighlightedBadges bh ON u.Id = bh.UserId
LEFT JOIN 
    PostHistoryAggregates phg ON u.Id = phg.UserId
LEFT JOIN 
    RankedPosts pp ON pp.OwnerUserId = u.Id AND pp.rn = 1
WHERE 
    u.Reputation > 1000 
ORDER BY 
    mu.TotalScore DESC, 
    mu.PostCount DESC;