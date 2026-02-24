WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalScore,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalScore,
    tu.AverageScore,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    STRING_AGG(DISTINCT p.Title, ', ') AS TopPosts
FROM 
    TopUsers tu
LEFT JOIN 
    Badges bh ON tu.UserId = bh.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = tu.UserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.TotalViews, tu.TotalScore, tu.AverageScore
ORDER BY 
    tu.TotalScore DESC;
