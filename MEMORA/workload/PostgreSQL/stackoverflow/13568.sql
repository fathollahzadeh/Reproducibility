WITH PostStats AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS PostCount, 
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ps.PostType, 
    ps.PostCount, 
    ps.AverageScore
FROM 
    PostStats ps
ORDER BY 
    ps.PostCount DESC;