SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(voteCount) AS TotalVotes,
    p.ViewCount,
    p.Score,
    CASE 
        WHEN p.PostTypeId = 1 THEN 'Question'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS voteCount FROM Votes GROUP BY PostId) v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
ORDER BY 
    p.CreationDate DESC;