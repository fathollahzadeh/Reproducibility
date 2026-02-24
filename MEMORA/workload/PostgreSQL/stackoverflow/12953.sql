
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS TotalComments,
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    U.CreationDate AS UserCreationDate,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    AVG(v.VoteTypeId) AS AverageVoteType, 
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p 
LEFT JOIN 
    Users U ON p.OwnerUserId = U.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2020-01-01' 
GROUP BY 
    p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.CreationDate, 
    U.DisplayName, U.Reputation, U.CreationDate
ORDER BY 
    p.ViewCount DESC;
