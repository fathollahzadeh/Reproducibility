SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    u.DisplayName AS AuthorName, 
    p.CreationDate AS PostDate, 
    p.ViewCount AS NumberOfViews, 
    p.Score AS PostScore
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  
ORDER BY 
    p.CreationDate DESC
LIMIT 10;