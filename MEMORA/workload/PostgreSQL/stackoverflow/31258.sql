
WITH RecursiveUserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.PostCount,
        U.QuestionCount,
        U.AnswerCount,
        U.TotalViews,
        U.AverageScore,
        R.BadgeName,
        R.BadgeRank
    FROM 
        UserPostStats U
    LEFT JOIN 
        RecursiveUserBadges R ON U.UserId = R.UserId AND R.BadgeRank = 1
    WHERE 
        U.PostCount > 10
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViews,
    TU.AverageScore,
    TU.BadgeName,
    COALESCE(TU.BadgeName, 'No Badge') AS BadgeStatus,
    CASE 
        WHEN TU.AverageScore > 50 THEN 'High Score User'
        WHEN TU.AverageScore BETWEEN 20 AND 50 THEN 'Moderate Score User'
        ELSE 'Low Score User'
    END AS UserScoreCategory
FROM 
    TopUsers TU
ORDER BY 
    TU.TotalViews DESC, TU.PostCount DESC;
