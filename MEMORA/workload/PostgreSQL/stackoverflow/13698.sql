
WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        AVG(COALESCE(u.Reputation, 0)) AS AvgReputation,
        SUM(CASE WHEN b.Date IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgViewCount,
    ps.AvgScore,
    ps.TotalAnswers,
    ps.TotalComments,
    us.DisplayName AS UserName,
    us.PostsCount,
    us.AvgReputation,
    us.TotalBadges
FROM 
    PostStatistics ps
CROSS JOIN 
    UserStatistics us
ORDER BY 
    ps.TotalPosts DESC, us.PostsCount DESC;
