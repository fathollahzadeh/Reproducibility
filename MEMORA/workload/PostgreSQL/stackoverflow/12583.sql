WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName, u.Reputation
    ORDER BY 
        u.Reputation DESC
    LIMIT 5
)

SELECT 
    pm.PostType,
    pm.PostCount,
    pm.AverageScore,
    pm.TotalViewCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.BadgeCount
FROM 
    PostMetrics pm
CROSS JOIN 
    TopUsers tu;