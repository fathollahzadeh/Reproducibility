WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(u.Reputation) AS TotalUserReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    PostCount,
    AverageViewCount,
    TotalUserReputation
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;