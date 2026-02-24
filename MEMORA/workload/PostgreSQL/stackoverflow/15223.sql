SELECT 
    Users.DisplayName AS UserName,
    Posts.Title AS PostTitle,
    Posts.CreationDate AS PostDate,
    Posts.ViewCount AS Views,
    Posts.Score AS Score
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1 
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;