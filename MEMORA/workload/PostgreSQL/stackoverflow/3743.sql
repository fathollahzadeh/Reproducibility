WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(Score) AS TotalScore,
        COUNT(DISTINCT PostId) AS TotalPosts
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(DISTINCT PostId) > 5
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 
)
SELECT 
    tu.OwnerDisplayName,
    tu.TotalScore,
    tu.TotalPosts,
    COALESCE(ub.BadgeName, 'No Gold Badge') AS GoldBadge
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.OwnerDisplayName = ub.DisplayName
ORDER BY 
    tu.TotalScore DESC, 
    tu.TotalPosts DESC
LIMIT 10;