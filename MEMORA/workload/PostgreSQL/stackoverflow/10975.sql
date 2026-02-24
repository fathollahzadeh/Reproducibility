SELECT 
    ph.PostId,
    COUNT(*) AS RevisionCount,
    MIN(ph.CreationDate) AS FirstRevisionDate,
    MAX(ph.CreationDate) AS LastRevisionDate,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    ph.PostId
ORDER BY 
    RevisionCount DESC;
