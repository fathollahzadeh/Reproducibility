SELECT 
    ph.PostHistoryTypeId,
    COUNT(*) AS HistoryCount,
    MIN(ph.CreationDate) AS FirstChangeDate,
    MAX(ph.CreationDate) AS LastChangeDate,
    MIN(ph.UserId) AS FirstUserId,
    MAX(ph.UserId) AS LastUserId
FROM 
    PostHistory ph
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    HistoryCount DESC;
