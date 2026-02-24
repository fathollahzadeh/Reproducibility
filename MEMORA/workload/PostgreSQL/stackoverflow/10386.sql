
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS DownVotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 ELSE 0 END), 0) AS AcceptedCount,
    p.ViewCount,
    p.Score,
    p.Tags,
    p.AnswerCount,
    p.CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation, p.ViewCount, p.Score, p.Tags, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
