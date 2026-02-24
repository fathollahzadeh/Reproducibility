
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AvgBountyAmount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(ph.Id) AS PostHistoryCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount
ORDER BY 
    p.ViewCount DESC;
