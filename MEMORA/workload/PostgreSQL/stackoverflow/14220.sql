SELECT 
    Ph.PostId,
    COUNT(*) AS RevisionCount,
    MIN(Ph.CreationDate) AS FirstRevisionDate,
    MAX(Ph.CreationDate) AS LastRevisionDate,
    MAX(Ph.CreationDate) - MIN(Ph.CreationDate) AS RevisionDuration,
    SUM(CASE WHEN Ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
    SUM(CASE WHEN Ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS DeleteUndeleteCount,
    SUM(CASE WHEN Ph.PostHistoryTypeId IN (24) THEN 1 ELSE 0 END) AS SuggestedEditCount
FROM 
    PostHistory Ph
JOIN 
    Posts P ON Ph.PostId = P.Id
WHERE 
    P.CreationDate >= '2022-01-01' 
GROUP BY 
    Ph.PostId
ORDER BY 
    RevisionCount DESC;