WITH PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.PostTypeId
), 
PostTypeNames AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName
    FROM 
        PostTypes pt
)

SELECT 
    ptn.PostTypeName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.AverageReputation
FROM 
    PostStatistics ps
JOIN 
    PostTypeNames ptn ON ps.PostTypeId = ptn.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;