WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
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
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostCounts
)
SELECT 
    u.DisplayName,
    uc.PostCount,
    uc.QuestionCount,
    uc.AnswerCount,
    uc.TotalViews,
    uc.TotalScore,
    t.PostRank,
    t.ScoreRank
FROM 
    Users u
JOIN 
    UserPostCounts uc ON u.Id = uc.UserId
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    t.PostRank <= 10 OR t.ScoreRank <= 10
ORDER BY 
    t.PostRank, t.ScoreRank;