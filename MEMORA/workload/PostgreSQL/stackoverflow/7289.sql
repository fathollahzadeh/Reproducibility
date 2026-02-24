
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(u.Reputation) AS AverageReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(v.BountyAmount) AS TotalBountyAmount
FROM 
    Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
WHERE 
    u.CreationDate > '2020-01-01'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    AverageReputation DESC
LIMIT 50;
