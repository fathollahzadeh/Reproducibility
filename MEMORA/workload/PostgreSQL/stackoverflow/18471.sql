
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, u.DisplayName 
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
