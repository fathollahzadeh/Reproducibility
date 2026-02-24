SELECT 
    ph.PostId,
    COUNT(ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastModified,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS ModifiedByUsers
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    ph.PostId
ORDER BY 
    HistoryCount DESC;
