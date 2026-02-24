SELECT 
    u.Id AS UserId,
    u.Reputation,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    COALESCE(SUM(c.CommentCount), 0) AS TotalComments,
    COALESCE(SUM(v.VoteCount), 0) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.Reputation, u.DisplayName
ORDER BY 
    u.Reputation DESC;