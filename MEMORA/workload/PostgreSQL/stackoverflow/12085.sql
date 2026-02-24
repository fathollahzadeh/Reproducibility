
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    u.DisplayName AS Author,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    p.CreationDate,
    p.LastActivityDate,
    p.Score,
    p.ViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, pt.Name, u.DisplayName, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
