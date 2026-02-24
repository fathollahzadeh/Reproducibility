
WITH UserPostCounts AS (
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
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCounts
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UserRank
FROM 
    TopUsers u
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank;
