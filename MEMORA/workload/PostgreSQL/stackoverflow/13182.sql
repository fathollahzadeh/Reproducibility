
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS Author,
    p.CreationDate AS PostDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    COUNT(v.Id) AS NumberOfVotes,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownVotes,
    COUNT(ph.Id) AS RevisionCount,
    MAX(ph.CreationDate) AS LastEditedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
