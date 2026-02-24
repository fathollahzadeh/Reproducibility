SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Tags.TagName,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
JOIN 
    Tags ON Posts.Id = Tags.ExcerptPostId
GROUP BY 
    Users.DisplayName, Posts.Title, Posts.CreationDate, Tags.TagName
ORDER BY 
    CommentCount DESC;
