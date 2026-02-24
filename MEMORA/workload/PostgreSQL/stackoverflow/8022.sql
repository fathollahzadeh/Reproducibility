WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    tu.OwnerDisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    ARRAY_AGG(p.Title ORDER BY p.Score DESC) AS TopPostTitles
FROM 
    TopUsers tu
JOIN 
    RankedPosts p ON tu.OwnerDisplayName = p.OwnerDisplayName
GROUP BY 
    tu.OwnerDisplayName, tu.TotalPosts, tu.TotalViews, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC;