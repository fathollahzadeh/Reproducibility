WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount END, 0)) AS AvgAnswers,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        SUM(u.Reputation) AS TotalReputation,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgAnswers,
    ps.AvgComments,
    ps.AcceptedAnswers,
    us.TotalUsers,
    us.TotalReputation,
    us.AvgReputation,
    us.TotalBadges
FROM 
    PostStats ps, UserStats us
ORDER BY 
    ps.TotalPosts DESC;