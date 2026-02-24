SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(badgeCount.TotalBadges, 0) AS TotalBadges,
    COALESCE(voteCount.TotalVotes, 0) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS TotalBadges 
     FROM Badges 
     GROUP BY UserId) badgeCount ON badgeCount.UserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS TotalVotes 
     FROM Votes 
     GROUP BY PostId) voteCount ON voteCount.PostId = p.Id
WHERE 
    p.CreationDate >= '2022-01-01' 
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;