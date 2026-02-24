WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswerCount,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgCommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgScore,
    ps.TotalViews,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    RANK() OVER (ORDER BY ps.TotalViews DESC) AS RankByViews
FROM 
    PostStats ps
ORDER BY 
    ps.TotalPosts DESC;