
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(u.Reputation) AS AverageReputation,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC
LIMIT 10;
