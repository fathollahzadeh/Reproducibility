SELECT 
    ph.PostId,
    COUNT(*) AS RevisionCount,
    MIN(ph.CreationDate) AS FirstRevisionDate,
    MAX(ph.CreationDate) AS LastRevisionDate,
    MAX(ph.CreationDate) - MIN(ph.CreationDate) AS TotalRevisionTime
FROM 
    PostHistory ph
GROUP BY 
    ph.PostId
ORDER BY 
    RevisionCount DESC;
