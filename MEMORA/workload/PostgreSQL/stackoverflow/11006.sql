
SELECT 
    u.Reputation AS UserReputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    AVG(p.Score) AS AverageQuestionScore,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(a.Id) AS AnswerCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON a.ParentId = p.Id 
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;
