WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ps.PostTypeName, 
    ps.PostCount, 
    ps.AvgViewCount, 
    ps.AvgScore,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts  
FROM 
    PostStats ps
ORDER BY 
    ps.PostCount DESC;