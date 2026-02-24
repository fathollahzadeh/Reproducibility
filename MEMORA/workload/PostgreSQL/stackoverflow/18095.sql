SELECT 
    Posts.Title, 
    Posts.CreationDate, 
    Users.DisplayName AS OwnerDisplayName, 
    Posts.Score, 
    Posts.ViewCount 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1  
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;