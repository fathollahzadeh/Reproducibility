WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    PostCount,
    COALESCE(AvgScore, 0) AS AvgScore,
    COALESCE(AvgViews, 0) AS AvgViews
FROM 
    PostStats
ORDER BY 
    PostCount DESC;