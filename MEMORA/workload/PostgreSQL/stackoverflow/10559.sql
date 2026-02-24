WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.TotalViews,
    ua.TotalScore,
    ua.CommentsCount,
    ua.BadgesCount,
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews AS PostTypeViews,
    ps.AverageScore
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.PostsCount > 0
ORDER BY 
    ua.TotalViews DESC, ua.TotalScore DESC, ua.PostsCount DESC;