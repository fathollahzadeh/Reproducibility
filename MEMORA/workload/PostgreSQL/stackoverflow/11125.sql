SELECT 
    ph.PostId,
    COUNT(ph.Id) AS HistoryCount,
    MIN(ph.CreationDate) AS FirstEditDate,
    MAX(ph.CreationDate) AS LastEditDate,
    STRING_AGG(DISTINCT p.Tags, ', ') AS TagsUsed,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    ph.PostId
ORDER BY 
    HistoryCount DESC;
