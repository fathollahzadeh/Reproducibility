SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    pt.Name AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2023-01-01'
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
