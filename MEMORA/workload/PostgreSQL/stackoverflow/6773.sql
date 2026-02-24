WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 1000
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(Id) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(tu.PostCount, 0) AS TopPosts,
    COALESCE(tu.TotalViews, 0) AS TotalPostViews,
    COALESCE(tu.AverageScore, 0) AS AvgPostScore
FROM 
    Users u
LEFT JOIN 
    TopUsers tu ON u.DisplayName = tu.OwnerDisplayName
WHERE 
    u.Reputation > 5000
ORDER BY 
    u.Reputation DESC, 
    TopPosts DESC;