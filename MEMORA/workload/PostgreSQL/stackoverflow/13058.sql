SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.CommentCount) AS AvgCommentsPerPost,
    AVG(p.AnswerCount) AS AvgAnswersPerPost
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;