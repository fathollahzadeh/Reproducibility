SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    v.CreationDate AS VoteCreationDate,
    vt.Name AS VoteTypeName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate > '2023-01-01'
ORDER BY 
    v.CreationDate DESC;
