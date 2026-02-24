
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS VoteScore,
    COUNT(c.Id) AS CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.CreationDate,
    p.LastActivityDate,
    p.PostTypeId
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR'  
GROUP BY 
    p.Id, p.Title, p.ViewCount, u.DisplayName, u.Reputation, p.CreationDate, p.LastActivityDate, p.PostTypeId
ORDER BY 
    VoteScore DESC, p.LastActivityDate DESC;
