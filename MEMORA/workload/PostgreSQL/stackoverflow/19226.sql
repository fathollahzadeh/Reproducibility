SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Users.DisplayName AS Owner,
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