SELECT 
    U.DisplayName AS UserDisplayName,
    Post.Title AS PostTitle,
    Post.CreationDate AS PostCreationDate,
    Post.Body AS PostBody,
    COUNT(C.CommentId) AS CommentCount
FROM 
    Posts Post
JOIN 
    Users U ON Post.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         Id as CommentId, 
         PostId 
     FROM 
         Comments) C ON Post.Id = C.PostId
WHERE 
    Post.PostTypeId = 1 
GROUP BY 
    U.DisplayName, Post.Title, Post.CreationDate, Post.Body
ORDER BY 
    Post.CreationDate DESC
LIMIT 10;