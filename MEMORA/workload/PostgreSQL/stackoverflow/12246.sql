WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COUNT(p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
)
SELECT 
    pm.PostType,
    pm.PostCount,
    pm.AvgViewCount,
    pm.AvgScore,
    um.UserId,
    um.Reputation,
    um.CreationDate,
    um.PostsCount
FROM 
    PostMetrics pm
JOIN 
    UserMetrics um ON um.PostsCount > 0
ORDER BY 
    pm.PostType;