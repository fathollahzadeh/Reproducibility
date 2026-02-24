SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.ViewCount,
    Posts.Score
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1  
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;