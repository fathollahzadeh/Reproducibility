
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    PH.UserDisplayName AS LastEditorDisplayName,
    PH.LastEditorUserId,
    PH.LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
LEFT JOIN 
    (SELECT 
        Ph.PostId, 
        Ph.UserDisplayName, 
        Ph.UserId AS LastEditorUserId, 
        Ph.CreationDate AS LastEditDate 
     FROM 
        PostHistory Ph 
     WHERE 
        Ph.PostHistoryTypeId IN (4, 5)) PH ON PH.PostId = p.Id
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, 
    u.DisplayName, u.Reputation, PH.UserDisplayName, PH.LastEditorUserId, PH.LastEditDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
