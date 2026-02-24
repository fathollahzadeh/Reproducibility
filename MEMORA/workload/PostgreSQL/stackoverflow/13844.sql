
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    AVG(vs.VoteCount) AS AverageScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) vs ON p.Id = vs.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
