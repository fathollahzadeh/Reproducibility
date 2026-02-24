WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
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
),
UserReputation AS (
    SELECT 
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)

SELECT 
    pm.PostTypeName,
    pm.PostCount,
    pm.AverageScore,
    pm.TotalComments,
    ur.DisplayName AS TopUser,
    ur.Reputation
FROM 
    PostMetrics pm
CROSS JOIN 
    UserReputation ur
ORDER BY 
    pm.PostCount DESC;