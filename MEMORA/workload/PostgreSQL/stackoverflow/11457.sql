SELECT 
    ph.PostHistoryTypeId,
    COUNT(*) AS HistoryCount,
    MIN(ph.CreationDate) AS FirstOccurrence,
    MAX(ph.CreationDate) AS LastOccurrence
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    HistoryCount DESC;
