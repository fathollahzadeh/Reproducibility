SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS Author,
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
