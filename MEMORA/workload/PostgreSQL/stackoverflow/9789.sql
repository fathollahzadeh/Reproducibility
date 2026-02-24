SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes,
    ht.Name AS LastHistoryType,
    ph.CreationDate AS LastHistoryDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.Reputation > 1000
    AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, ht.Name, ph.CreationDate
ORDER BY 
    p.Score DESC, CommentCount DESC
LIMIT 50;