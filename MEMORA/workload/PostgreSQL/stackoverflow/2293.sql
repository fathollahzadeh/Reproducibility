WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(b.Class), 0) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopBadgedUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalBadgePoints,
        RANK() OVER (ORDER BY TotalBadgePoints DESC) AS BadgeRank
    FROM 
        UserStats
)
SELECT 
    ub.UserId,
    ub.Reputation,
    ub.TotalPosts,
    ub.TotalBadgePoints,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    STRING_AGG(DISTINCT rp.Title, '; ') AS RecentPostTitles
FROM 
    TopBadgedUsers ub
LEFT JOIN 
    RankedPosts rp ON ub.UserId = rp.OwnerUserId
WHERE 
    ub.BadgeRank <= 10
GROUP BY 
    ub.UserId, ub.Reputation, ub.TotalPosts, ub.TotalBadgePoints
ORDER BY 
    ub.TotalBadgePoints DESC, ub.Reputation DESC;
