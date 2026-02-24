SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount
     FROM 
         Votes
     GROUP BY 
         PostId) v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    p.CreationDate DESC;