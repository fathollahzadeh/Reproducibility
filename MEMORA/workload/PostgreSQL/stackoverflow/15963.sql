SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.Score,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Comments ON Comments.PostId = Posts.Id
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Users.DisplayName, Posts.Title, Posts.CreationDate, Posts.Score
ORDER BY 
    Posts.Score DESC
LIMIT 10;