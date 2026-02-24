WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        Owner,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        Owner
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tu.Owner,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    ub.BadgeCount
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.Owner = ub.DisplayName
ORDER BY 
    tu.TotalScore DESC, 
    tu.PostCount DESC;