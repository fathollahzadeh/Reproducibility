
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT * FROM UserPostStats
    ORDER BY TotalScore DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    U.QuestionCount,
    U.AnswerCount,
    B.Name AS BadgeName,
    B.Class AS BadgeClass
FROM TopUsers U
LEFT JOIN Badges B ON U.UserId = B.UserId
ORDER BY U.TotalScore DESC;
