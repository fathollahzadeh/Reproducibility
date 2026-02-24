
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    p.ViewCount,
    p.Score,
    bt.Name AS BadgeName,
    bh.UserDisplayName AS HistoryUserDisplayName,
    bh.CreationDate AS HistoryCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges bt ON u.Id = bt.UserId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score, bt.Name, bh.UserDisplayName, bh.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
