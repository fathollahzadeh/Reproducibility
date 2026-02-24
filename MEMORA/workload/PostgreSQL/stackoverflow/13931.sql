WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostTypeName,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViewCount,
    ps.AvgUserReputation
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
ORDER BY 
    ps.PostCount DESC;