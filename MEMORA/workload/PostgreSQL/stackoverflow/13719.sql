WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AvgScore,
    TotalComments
FROM 
    PostStats
ORDER BY 
    PostCount DESC;