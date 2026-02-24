SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Votes.VoteTypeId
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
WHERE 
    Posts.PostTypeId = 1 
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;