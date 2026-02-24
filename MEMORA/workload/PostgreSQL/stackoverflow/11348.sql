WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY QuestionCount DESC) AS RankByQuestions,
        RANK() OVER (ORDER BY AnswerCount DESC) AS RankByAnswers
    FROM 
        UserPostCounts
)

SELECT 
    u.DisplayName,
    u.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.RankByPosts,
    t.RankByQuestions,
    t.RankByAnswers
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.RankByPosts <= 10
ORDER BY 
    t.RankByPosts;