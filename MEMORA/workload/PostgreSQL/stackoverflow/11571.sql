SELECT 
    u.Id AS UserId,
    u.Reputation,
    COALESCE(p.PostCount, 0) AS PostCount,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM 
    Users u
LEFT JOIN 
    (SELECT OwnerUserId, COUNT(*) AS PostCount
     FROM Posts
     GROUP BY OwnerUserId) p ON u.Id = p.OwnerUserId
LEFT JOIN 
    (SELECT OwnerUserId, COUNT(*) AS AnswerCount
     FROM Posts
     WHERE PostTypeId = 2
     GROUP BY OwnerUserId) a ON u.Id = a.OwnerUserId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS CommentCount
     FROM Comments
     GROUP BY UserId) c ON u.Id = c.UserId
ORDER BY 
    u.Reputation DESC;