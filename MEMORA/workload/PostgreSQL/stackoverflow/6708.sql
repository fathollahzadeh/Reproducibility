WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(PostId) >= 3
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore
FROM 
    Users u
JOIN 
    TopUsers tu ON u.DisplayName = tu.OwnerDisplayName
WHERE 
    u.Reputation > 1000
ORDER BY 
    tu.TotalScore DESC, tu.TotalViews DESC;