
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AvgViewsPerPost,
    AVG(p.Score) AS AvgScorePerPost,
    COUNT(DISTINCT c.Id) AS TotalComments 
FROM 
    Users u
JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    u.DisplayName, u.Id
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    TotalPosts DESC;
