
SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    COUNT(c.Id) AS CommentCount, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate
ORDER BY 
    p.CreationDate DESC;
