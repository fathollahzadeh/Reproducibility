SELECT 
    ph.PostId, 
    ph.UserId, 
    COUNT(*) AS RevisionCount, 
    MIN(ph.CreationDate) AS FirstRevisionDate, 
    MAX(ph.CreationDate) AS LastRevisionDate 
FROM 
    PostHistory ph 
JOIN 
    Posts p ON ph.PostId = p.Id 
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    ph.PostId, ph.UserId 
ORDER BY 
    RevisionCount DESC 
LIMIT 10;
