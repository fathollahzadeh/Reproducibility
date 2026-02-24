WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AvgViewCount,
    TotalComments
FROM 
    PostStats
ORDER BY 
    PostCount DESC;