SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
    COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    AVG(COALESCE(p.ViewCount, 0)) AS AverageViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;