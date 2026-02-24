
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(p.Score) AS AvgScore,
        AVG(CASE WHEN p.ViewCount > 0 THEN p.Score / p.ViewCount ELSE 0 END) AS ScorePerView
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViewCount,
        AvgScore,
        ScorePerView,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostStats
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViewCount,
    AvgScore,
    ScorePerView
FROM 
    TopActiveUsers
WHERE 
    Rank <= 10;
