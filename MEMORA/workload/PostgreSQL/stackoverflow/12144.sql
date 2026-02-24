SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    p.ViewCount,
    (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, p.ViewCount
ORDER BY 
    TotalVotes DESC, TotalComments DESC, p.ViewCount DESC
LIMIT 100;