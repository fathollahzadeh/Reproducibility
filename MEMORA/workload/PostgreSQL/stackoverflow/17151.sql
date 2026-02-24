SELECT 
    Users.DisplayName, 
    COUNT(Posts.Id) AS PostCount, 
    SUM(Posts.Score) AS TotalScore
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
GROUP BY 
    Users.DisplayName
ORDER BY 
    TotalScore DESC
LIMIT 10;
