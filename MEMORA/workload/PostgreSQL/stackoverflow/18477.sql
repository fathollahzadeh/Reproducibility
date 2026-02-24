SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.Score, 
    Posts.CreationDate 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 
ORDER BY 
    Posts.Score DESC 
LIMIT 10;
