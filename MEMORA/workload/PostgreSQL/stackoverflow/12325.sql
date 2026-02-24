
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS ActivePostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    ActivePostCount,
    AvgScore
FROM 
    PostStats
ORDER BY 
    ActivePostCount DESC;
