WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.PositiveScoreCount,
    UPS.AverageScore,
    UPS.LastPostDate,
    B.UserBadgeCount
FROM 
    UserPostStats UPS
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS UserBadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON UPS.UserId = B.UserId
ORDER BY 
    UPS.PostCount DESC
LIMIT 100;