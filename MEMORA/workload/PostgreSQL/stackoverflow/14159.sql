SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE 
        WHEN v.VoteTypeId = 2 THEN 1 
        ELSE 0 
    END) AS UpVoteCount,
    SUM(CASE 
        WHEN v.VoteTypeId = 3 THEN 1 
        ELSE 0 
    END) AS DownVoteCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, CommentCount DESC, VoteCount DESC
LIMIT 100;