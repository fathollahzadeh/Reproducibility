SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS UserCreatedPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.CommentCount) AS TotalComments,
    SUM(p.FavoriteCount) AS TotalFavorites
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;