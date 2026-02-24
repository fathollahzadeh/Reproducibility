
SELECT 
    p.Id AS PostID,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.LastActivityDate AS PostLastActivityDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    p.AnswerCount AS NumberOfAnswers,
    p.CommentCount AS NumberOfComments,
    p.ClosedDate AS PostClosedDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, 
    p.AnswerCount, p.CommentCount, p.ClosedDate, 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC 
LIMIT 100;
