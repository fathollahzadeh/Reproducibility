SELECT 
    ph.UserId,
    COUNT(*) AS TotalEdits,
    MAX(ph.CreationDate) AS LastEditDate,
    MIN(ph.CreationDate) AS FirstEditDate
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6, 10, 11, 12)  
GROUP BY 
    ph.UserId
ORDER BY 
    TotalEdits DESC;