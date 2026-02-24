SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.Score,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
GROUP BY 
    Users.DisplayName, Posts.Title, Posts.CreationDate, Posts.Score
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;
