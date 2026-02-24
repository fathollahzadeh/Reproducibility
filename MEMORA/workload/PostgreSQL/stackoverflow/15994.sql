SELECT 
    Users.DisplayName,
    COUNT(DISTINCT Posts.Id) AS PostCount,
    SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
    AVG(Users.Reputation) AS AverageReputation
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
GROUP BY 
    Users.DisplayName
ORDER BY 
    PostCount DESC;
