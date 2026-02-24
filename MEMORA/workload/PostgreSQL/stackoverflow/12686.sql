
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score AS PostScore,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(b.Name, ', ') AS BadgeNames
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
LEFT JOIN 
    Comments c ON c.PostId = p.Id 
LEFT JOIN 
    Votes v ON v.PostId = p.Id 
LEFT JOIN 
    Badges b ON b.UserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT a.Id) > 5 
ORDER BY 
    p.CreationDate DESC;
