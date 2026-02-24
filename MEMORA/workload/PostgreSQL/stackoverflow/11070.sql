
SELECT 
    p.Id AS PostID,
    p.Title AS PostTitle,
    pt.Name AS PostType,
    u.Id AS UserID,
    u.DisplayName AS UserName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    p.ViewCount AS ViewCount,
    p.Score AS Score,
    p.CreationDate AS PostCreationDate
FROM 
    Posts p
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, pt.Name, u.Id, u.DisplayName, p.ViewCount, p.Score, p.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
