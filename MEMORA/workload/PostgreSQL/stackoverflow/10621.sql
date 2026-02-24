
WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2023-10-01'  
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    TotalVotes
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;
