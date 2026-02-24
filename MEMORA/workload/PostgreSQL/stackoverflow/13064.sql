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
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM 
        UserPostCounts
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    PostRank,
    QuestionRank,
    AnswerRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10 OR QuestionRank <= 10 OR AnswerRank <= 10
ORDER BY 
    PostRank, QuestionRank, AnswerRank;