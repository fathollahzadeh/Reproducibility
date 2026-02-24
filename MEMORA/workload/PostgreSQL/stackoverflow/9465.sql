
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(EXTRACT(EPOCH FROM (COALESCE(p.LastActivityDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate))) AS AvgPostAgeSeconds
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
        TotalScore,
        QuestionCount,
        AnswerCount,
        AvgPostAgeSeconds,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity
),
StackOverflowStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT u.Id) AS TotalUsers,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.QuestionCount,
    tu.AnswerCount,
    (SELECT TotalPosts FROM StackOverflowStats) AS TotalPosts,
    (SELECT TotalUsers FROM StackOverflowStats) AS TotalUsers,
    (SELECT TotalQuestions FROM StackOverflowStats) AS TotalQuestions,
    (SELECT TotalAnswers FROM StackOverflowStats) AS TotalAnswers,
    (SELECT AvgPostScore FROM StackOverflowStats) AS AvgPostScore
FROM 
    TopUsers tu
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.TotalScore DESC;
