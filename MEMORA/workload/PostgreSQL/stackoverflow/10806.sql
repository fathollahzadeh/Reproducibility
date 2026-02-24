
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.ViewCount,
    p.Score,
    T.TagName,
    COALESCE(TAG_COUNT.Count, 0) AS TagCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS Count 
     FROM Votes 
     GROUP BY PostId) TAG_COUNT ON p.Id = TAG_COUNT.PostId
LEFT JOIN 
    (SELECT 
        pt.Id, 
        STRING_AGG(t.TagName, ', ') AS TagName
     FROM 
        Posts p
     JOIN 
        Tags t ON t.ExcerptPostId = p.Id
     JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
     GROUP BY 
        pt.Id) AS T ON p.PostTypeId = T.Id
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score, T.TagName, TAG_COUNT.Count
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
