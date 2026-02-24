SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
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
    Users.DisplayName, Posts.Title, Posts.CreationDate
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;