SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
         Votes
     GROUP BY 
         PostId) v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(Id) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(Id) AS BadgeCount
     FROM 
         Badges
     GROUP BY 
         UserId) b ON u.Id = b.UserId
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'  
ORDER BY 
    p.CreationDate DESC;