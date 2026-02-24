
SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.CommentCount, p.AnswerCount, u.DisplayName, u.Reputation
ORDER BY 
    VoteCount DESC, ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
