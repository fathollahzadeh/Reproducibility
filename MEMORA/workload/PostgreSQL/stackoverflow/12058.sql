
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    COUNT(v.Id) AS TotalVotes,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes, 
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownvotes 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '6 month' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
