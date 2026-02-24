
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(voteTypeValue) AS AverageVoteType
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT Id, VoteTypeId, 
            CASE 
                WHEN VoteTypeId = 1 THEN 1
                WHEN VoteTypeId = 2 THEN 1
                WHEN VoteTypeId = 3 THEN -1
                ELSE 0 
            END AS voteTypeValue
     FROM Votes) vType ON v.Id = vType.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
