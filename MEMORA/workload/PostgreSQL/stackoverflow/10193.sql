
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.CreationDate >= '2021-01-01'  
    AND p.PostTypeId IN (1, 2)  
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
ORDER BY 
    u.Reputation DESC, p.Score DESC;
