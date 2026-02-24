
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    pt.Name AS PostType,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    p.AnswerCount,
    p.CommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name, u.DisplayName, 
    p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
