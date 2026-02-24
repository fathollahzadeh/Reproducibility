WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    pt.Name AS PostType,
    pc.TotalPosts,
    pc.UniqueUsers,
    us.TotalPosts AS PostsByUsers,
    us.TotalScore,
    us.TotalViews,
    bc.TotalBadges
FROM 
    PostCounts pc
JOIN 
    PostTypes pt ON pc.PostTypeId = pt.Id
LEFT JOIN 
    UserStatistics us ON us.TotalPosts > 0
LEFT JOIN 
    BadgeCounts bc ON bc.UserId = us.UserId
ORDER BY 
    pc.TotalPosts DESC;