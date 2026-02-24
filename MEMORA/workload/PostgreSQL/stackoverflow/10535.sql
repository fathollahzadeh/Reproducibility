WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT u.Id) AS TotalUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    TotalPosts,
    AverageScore,
    TotalUsers
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;