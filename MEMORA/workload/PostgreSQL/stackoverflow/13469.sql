WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.CommentCount IS NOT NULL THEN p.CommentCount ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN p.AnswerCount IS NOT NULL THEN p.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    ps.TotalComments,
    ps.TotalAnswers,
    us.DisplayName,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
LEFT JOIN 
    UserStats us ON us.TotalBadges > 0 
ORDER BY 
    ps.TotalPosts DESC, us.TotalBadges DESC;