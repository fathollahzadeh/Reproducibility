
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN p.PostTypeId = 1 THEN 'Question' 
        WHEN p.PostTypeId = 2 THEN 'Answer' 
        ELSE 'Other' 
    END AS PostType,
    p.ViewCount,
    p.LastActivityDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2020-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.ViewCount, p.LastActivityDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
