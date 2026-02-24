WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, B.Name, B.Class
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(CASE WHEN Class = 1 THEN BadgeCount * 3 WHEN Class = 2 THEN BadgeCount * 2 WHEN Class = 3 THEN BadgeCount END) AS TotalScore
    FROM UserBadges
    GROUP BY UserId, DisplayName
    ORDER BY TotalScore DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    T.DisplayName,
    PS.PostCount,
    PS.TotalViews,
    PS.AverageScore,
    PS.QuestionCount,
    PS.AnswerCount
FROM TopUsers T
JOIN PostStats PS ON T.UserId = PS.OwnerUserId
ORDER BY T.TotalScore DESC, PS.TotalViews DESC;
