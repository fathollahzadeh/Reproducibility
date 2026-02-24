
WITH RecentUsers AS (
    SELECT Id
    FROM Users
    WHERE LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
),
QuestionStats AS (
    SELECT 
        COUNT(*) AS TotalQuestions,
        AVG(Score) AS AverageScore
    FROM Posts
    WHERE PostTypeId = 1 
)

SELECT 
    (SELECT TotalQuestions FROM QuestionStats) AS TotalQuestions,
    (SELECT AverageScore FROM QuestionStats) AS AverageScore,
    (SELECT COUNT(*) FROM RecentUsers) AS ActiveUsers
FROM 
    (SELECT 1) AS DUAL;
