WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount
    FROM 
        Users u
    JOIN 
        UserPostCounts up ON u.Id = up.OwnerUserId
    WHERE 
        u.Reputation > 0
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBountyAmount
FROM 
    ActiveUsers au
LEFT JOIN 
    Comments c ON c.UserId = au.UserId
LEFT JOIN 
    Votes v ON v.UserId = au.UserId
GROUP BY 
    au.UserId, au.DisplayName, au.Reputation, au.PostCount, au.QuestionCount, au.AnswerCount
ORDER BY 
    au.Reputation DESC, au.PostCount DESC;