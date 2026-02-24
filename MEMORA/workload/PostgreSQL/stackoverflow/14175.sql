WITH PostCounts AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    pt.Name AS PostType,
    pc.TotalPosts,
    pc.RecentPosts,
    ua.UserId,
    ua.Reputation,
    ua.TotalPosts AS UserTotalPosts,
    ua.RecentPosts AS UserRecentPosts
FROM 
    PostCounts pc
JOIN 
    PostTypes pt ON pc.PostTypeId = pt.Id
LEFT JOIN 
    UserActivity ua ON ua.TotalPosts > 0
ORDER BY 
    pc.TotalPosts DESC, ua.Reputation DESC;