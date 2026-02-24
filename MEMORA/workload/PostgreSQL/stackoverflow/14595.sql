WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation
    FROM 
        Users
)
SELECT 
    ur.UserId,
    ur.Reputation,
    upc.PostCount,
    upc.QuestionCount,
    upc.AnswerCount,
    upc.WikiCount
FROM 
    UserReputation ur
JOIN 
    UserPostCounts upc ON ur.UserId = upc.UserId
ORDER BY 
    ur.Reputation DESC, 
    upc.PostCount DESC
LIMIT 100;