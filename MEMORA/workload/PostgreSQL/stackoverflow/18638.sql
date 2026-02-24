
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Author, 
    COUNT(c.Id) AS CommentCount, 
    SUM(v.vote_value) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
        PostId, 
        CASE 
            WHEN VoteTypeId = 2 THEN 1 
            WHEN VoteTypeId = 3 THEN -1 
            ELSE 0 
        END AS vote_value
     FROM 
        Votes) v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
