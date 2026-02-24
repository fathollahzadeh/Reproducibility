SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.CommentCount) AS AverageComments,
    AVG(p.AnswerCount) AS AverageAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;