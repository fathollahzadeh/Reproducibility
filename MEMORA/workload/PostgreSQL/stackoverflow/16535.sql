SELECT 
    Users.DisplayName, 
    COUNT(Posts.Id) AS TotalPosts, 
    SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
GROUP BY 
    Users.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10;
