
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    COUNT(v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2022-01-01'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.Reputation, u.DisplayName
ORDER BY 
    p.Score DESC, VoteCount DESC, p.CreationDate DESC
LIMIT 100;
