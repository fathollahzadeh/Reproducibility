
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.CreationDate AS PostCreationDate,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, u.DisplayName, u.Reputation, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
