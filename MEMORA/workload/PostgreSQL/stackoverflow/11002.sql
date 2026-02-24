WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        AVG(p.AnswerCount) AS AvgAnswersPerQuestion
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
        COUNT(DISTINCT CASE WHEN u.UpVotes > 0 THEN u.Id END) AS ActiveUsers,
        SUM(CASE WHEN u.LastAccessDate > cast('2024-10-01' as date) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentUsers
    FROM 
        Users u
),

CommentStats AS (
    SELECT 
        COUNT(c.Id) AS TotalComments,
        AVG(LENGTH(c.Text)) AS AvgCommentLength,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM 
        Comments c
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgAnswersPerQuestion,
    us.TotalUsers,
    us.TotalReputation,
    us.AvgReputation,
    us.ActiveUsers,
    us.RecentUsers,
    cs.TotalComments,
    cs.AvgCommentLength,
    cs.PositiveComments
FROM 
    PostStats ps,
    UserStats us,
    CommentStats cs
ORDER BY 
    ps.TotalPosts DESC;