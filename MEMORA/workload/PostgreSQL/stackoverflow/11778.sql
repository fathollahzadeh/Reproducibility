SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(p.AnswerCount) AS AvgAnswers,
    AVG(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS AvgCommentsPerPost,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadgesEarned
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;