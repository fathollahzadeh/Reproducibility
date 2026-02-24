SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    v.VoteTypeId AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, v.VoteTypeId
ORDER BY 
    VoteCount DESC
LIMIT 10;
