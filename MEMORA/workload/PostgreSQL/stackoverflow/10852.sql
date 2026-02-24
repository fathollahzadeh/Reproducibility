WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostTypeName,
        AVG(p.Score) AS AverageScore,
        MAX(p.ViewCount) AS MaxViewCount,
        COUNT(DISTINCT u.Id) AS ActiveUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        pt.Name
),
UserMetrics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        COUNT(CASE WHEN Reputation > 1000 THEN 1 END) AS HighReputationUsers
    FROM 
        Users
)

SELECT 
    pm.PostTypeName,
    pm.AverageScore,
    pm.MaxViewCount,
    um.TotalUsers,
    um.HighReputationUsers
FROM 
    PostMetrics pm,
    UserMetrics um
ORDER BY 
    pm.AverageScore DESC;