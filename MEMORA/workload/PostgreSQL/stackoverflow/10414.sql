
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    AVG(COALESCE(EXTRACT(EPOCH FROM (h.CreationDate - p.CreationDate)), 0)) AS AverageEditTime,
    MAX(h.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    PostHistory h ON h.PostId = p.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
