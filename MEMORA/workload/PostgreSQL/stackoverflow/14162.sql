WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
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
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation
FROM 
    PostStats ps
CROSS JOIN 
    (SELECT DisplayName, Reputation FROM TopUsers WHERE Rank <= 10) tu
ORDER BY 
    ps.TotalPosts DESC;