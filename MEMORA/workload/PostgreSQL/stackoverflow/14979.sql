WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserReputation AS (
    SELECT 
        u.Reputation,
        COUNT(*) AS UserPostCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Reputation
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    pc.AvgScore,
    pc.AvgViewCount,
    ur.Reputation,
    ur.UserPostCount
FROM 
    PostCounts pc
JOIN 
    UserReputation ur ON ur.UserPostCount > 0
ORDER BY 
    pc.TotalPosts DESC, ur.Reputation DESC;