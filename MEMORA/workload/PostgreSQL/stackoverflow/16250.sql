
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    ct.Name AS CloseReason
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
LEFT JOIN 
    CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount, ct.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
