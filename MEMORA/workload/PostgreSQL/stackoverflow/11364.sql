WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
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
    LIMIT 10
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViews,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount
FROM 
    PostStats ps
CROSS JOIN 
    TopUsers tu
ORDER BY 
    ps.PostType;