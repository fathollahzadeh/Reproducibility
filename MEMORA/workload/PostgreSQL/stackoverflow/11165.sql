
WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    upc.UserId,
    upc.DisplayName,
    upc.PostCount,
    upc.QuestionCount,
    upc.AnswerCount,
    COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
    u.Reputation,
    u.CreationDate
FROM 
    UserPostCount upc
JOIN 
    Users u ON upc.UserId = u.Id
LEFT JOIN 
    UserBadgeCount ubc ON upc.UserId = ubc.UserId
ORDER BY 
    upc.PostCount DESC, 
    u.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
