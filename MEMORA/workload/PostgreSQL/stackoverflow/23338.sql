
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(pt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeType
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    ru.ViewCount,
    ru.Score AS PostScore,
    tu.DisplayName AS Owner,
    tu.TotalScore,
    tu.PostCount,
    cb.CloseReasons,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeType = 1 THEN 'Gold'
        WHEN ub.HighestBadgeType = 2 THEN 'Silver'
        WHEN ub.HighestBadgeType = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cb ON ru.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    ru.Rank <= 5
    AND (ru.Score >= 10 OR ru.ViewCount > 100)
ORDER BY 
    ru.ViewCount DESC, tu.TotalScore DESC, cb.CreationDate DESC
LIMIT 100;
