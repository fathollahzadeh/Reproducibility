SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Owner,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    pb.Name AS PostType,
    bt.Name AS BadgeName,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId = p.Id) AS RelatedPostsCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pb ON p.PostTypeId = pb.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT 
         UserId, 
         STRING_AGG(Name, ', ') AS Name 
     FROM 
         Badges 
     GROUP BY 
         UserId) bt ON u.Id = bt.UserId 
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, pb.Name, bt.Name
ORDER BY 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC, 
    p.CreationDate DESC
LIMIT 100;
