WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND
        p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
    ORDER BY 
        TotalScore DESC, TotalViews DESC
    LIMIT 10
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate,
    ru.DisplayName AS TopUser,
    ru.BadgeCount,
    ru.TotalScore,
    ru.TotalViews
FROM 
    RankedPosts rp
JOIN 
    TopUsers ru ON rp.OwnerDisplayName = ru.DisplayName
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    ru.TotalScore DESC;