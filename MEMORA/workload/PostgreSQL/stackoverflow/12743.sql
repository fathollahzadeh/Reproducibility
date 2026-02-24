
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    COUNT(DISTINCT v.UserId) AS UniqueVoters,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON v.UserId = u.Id
GROUP BY 
    p.Id, p.Title, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
