
SELECT 
    ph.PostHistoryTypeId, 
    COUNT(*) AS RevisionCount, 
    MIN(ph.CreationDate) AS FirstRevisionDate, 
    MAX(ph.CreationDate) AS LastRevisionDate, 
    AVG(EXTRACT(EPOCH FROM COALESCE(ph2.CreationDate, CURRENT_TIMESTAMP) - ph.CreationDate)) AS AvgTimeBetweenRevisions
FROM 
    PostHistory ph
LEFT JOIN 
    PostHistory ph2 ON ph.PostId = ph2.PostId AND ph.CreationDate < ph2.CreationDate
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    RevisionCount DESC;
