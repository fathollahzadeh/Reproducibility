SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadgesCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
ORDER BY 
    p.ViewCount DESC  
LIMIT 100;