
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, pt.Name, u.Id, u.DisplayName, u.Reputation, 
    p.CreationDate, p.LastActivityDate, p.ViewCount, 
    p.AnswerCount, p.CommentCount, p.FavoriteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
