WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
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
        TotalScore,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostCounts
)

SELECT 
    u.DisplayName,
    uc.PostCount,
    uc.TotalScore,
    uc.QuestionCount,
    uc.AnswerCount,
    uc.Rank
FROM 
    TopUsers uc
JOIN 
    Users u ON uc.UserId = u.Id
WHERE 
    uc.Rank <= 10
ORDER BY 
    uc.Rank;