SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(pv.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pv.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    DATE_PART('epoch', cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate) AS AgeInSeconds
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId,
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
     FROM 
         Votes
     GROUP BY 
         PostId) pv ON p.Id = pv.PostId
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT DISTINCT 
         Id AS AcceptedAnswerId 
     FROM 
         Posts 
     WHERE 
         PostTypeId = 2) a ON p.AcceptedAnswerId = a.AcceptedAnswerId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC;