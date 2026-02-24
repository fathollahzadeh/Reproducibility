
SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Users.DisplayName AS Owner,
    Posts.CreationDate,
    Posts.Score,
    Posts.ViewCount,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
GROUP BY 
    Posts.Id, Posts.Title, Users.DisplayName, Posts.CreationDate, Posts.Score, Posts.ViewCount
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;
