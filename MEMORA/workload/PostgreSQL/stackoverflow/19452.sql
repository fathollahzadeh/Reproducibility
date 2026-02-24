SELECT 
    Users.DisplayName AS UserName,
    Posts.Title AS PostTitle,
    Posts.CreationDate AS PostDate,
    Posts.Score AS PostScore,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
WHERE 
    Posts.PostTypeId = 1  
GROUP BY 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Posts.Score
ORDER BY 
    PostDate DESC
LIMIT 10;