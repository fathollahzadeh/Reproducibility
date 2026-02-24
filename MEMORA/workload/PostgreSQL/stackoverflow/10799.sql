SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(uv.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(dv.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(u.Reputation, 0) AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS UpVoteCount 
     FROM Votes 
     WHERE VoteTypeId = 2 
     GROUP BY PostId) uv ON p.Id = uv.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS DownVoteCount 
     FROM Votes 
     WHERE VoteTypeId = 3 
     GROUP BY PostId) dv ON p.Id = dv.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    p.CreationDate DESC
LIMIT 100;