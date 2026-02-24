
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    v.VoteTypeId,
    COUNT(c.Id) AS CommentCount,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.FavoriteCount,
    PH.Comment AS PostHistoryComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    PostHistory PH ON PH.PostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation, t.TagName, v.VoteTypeId, 
    p.ViewCount, p.Score, p.AnswerCount, p.FavoriteCount, PH.Comment
ORDER BY 
    p.CreationDate DESC 
LIMIT 100;
