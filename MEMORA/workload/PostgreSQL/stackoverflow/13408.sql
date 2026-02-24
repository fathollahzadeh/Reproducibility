
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.AnswerCount AS TotalAnswers,
    p.FavoriteCount AS TotalFavorites,
    p.LastActivityDate AS LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.FavoriteCount, p.LastActivityDate
ORDER BY 
    PostScore DESC, PostCreationDate DESC
LIMIT 100;
