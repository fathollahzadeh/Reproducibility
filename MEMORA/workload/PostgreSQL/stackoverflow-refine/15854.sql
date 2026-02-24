
SELECT 
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS Author,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Posts.Title, Posts.CreationDate, Users.DisplayName
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
