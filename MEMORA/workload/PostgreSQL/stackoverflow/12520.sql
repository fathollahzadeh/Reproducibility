
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    p.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    CASE 
        WHEN ph.PostId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed,
    COUNT(v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AvgBounty
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.Tags, 
    u.DisplayName, u.Reputation, ph.PostId
ORDER BY 
    p.CreationDate DESC;
