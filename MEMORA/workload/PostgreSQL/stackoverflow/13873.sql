WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(pt.Id) AS PostTypeCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.TotalScore,
    ur.TotalViews,
    au.PostTypeCount,
    au.QuestionCount,
    au.AnswerCount
FROM UserReputation ur
JOIN ActiveUsers au ON ur.UserId = au.UserId
ORDER BY ur.Reputation DESC;