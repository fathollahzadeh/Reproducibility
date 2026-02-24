WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FilteredUsers AS (
    SELECT 
        u.*,
        ui.TotalBounty,
        ui.BadgeCount,
        ui.AvgPostScore
    FROM 
        Users u
    JOIN 
        UserInfo ui ON u.Id = ui.UserId
    WHERE 
        ui.Reputation > 1000 AND 
        ui.BadgeCount > 5 AND 
        ui.TotalBounty > 0
)
SELECT 
    fu.DisplayName,
    fu.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    MAX(fu.AvgPostScore) AS MaxAvgPostScore,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    FilteredUsers fu
JOIN 
    Posts p ON fu.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON fu.Id = b.UserId
WHERE 
    p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
GROUP BY 
    fu.DisplayName, fu.Reputation
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    TotalScore DESC;