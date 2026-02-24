SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    MAX(p.ViewCount) AS MaxViewCount,
    MIN(p.ViewCount) AS MinViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS AuthorCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;