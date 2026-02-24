WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageUserReputation,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostTypeName,
    ps.PostCount,
    ps.AverageUserReputation,
    ps.TotalViews,
    ps.TotalScore
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
ORDER BY 
    ps.PostCount DESC;