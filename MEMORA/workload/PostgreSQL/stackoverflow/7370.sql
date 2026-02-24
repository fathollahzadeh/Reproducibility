
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
BadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    COALESCE(ps.AverageViews, 0) AS AverageViews,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges
FROM 
    UserActivity ua
LEFT JOIN 
    PostStatistics ps ON ua.UserId = ps.UserId
LEFT JOIN 
    BadgeCount bc ON ua.UserId = bc.UserId
ORDER BY 
    ua.TotalPosts DESC, ua.TotalUpvotes DESC;
