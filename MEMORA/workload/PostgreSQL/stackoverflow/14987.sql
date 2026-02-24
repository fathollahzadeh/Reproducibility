
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags,
    COALESCE(p.AnswerCount, 0) AS AnswerCount,
    COALESCE(p.CommentCount, 0) AS CommentCount,
    COALESCE(p.ViewCount, 0) AS ViewCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')  
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
