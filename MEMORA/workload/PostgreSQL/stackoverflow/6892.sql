SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    COUNT(DISTINCT ph.UserId) AS UniqueEditors,
    MAX(ph.CreationDate) AS LastEditDate,
    p.CreationDate,
    p.ViewCount,
    COALESCE(pl.RelatedPostCount, 0) AS RelatedPostCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS RelatedPostCount 
     FROM 
         PostLinks 
     GROUP BY 
         PostId) pl ON p.Id = pl.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, pl.RelatedPostCount
HAVING 
    COUNT(c.Id) > 5 AND 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
ORDER BY 
    p.ViewCount DESC, UpVoteCount DESC
LIMIT 100;