WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.BadgeCount,
        UB.HighestBadgeClass,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalScore,
        PS.AverageScore
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    CS.DisplayName,
    CS.BadgeCount,
    CS.HighestBadgeClass,
    COALESCE(CS.PostCount, 0) AS TotalPosts,
    COALESCE(CS.QuestionCount, 0) AS TotalQuestions,
    COALESCE(CS.AnswerCount, 0) AS TotalAnswers,
    COALESCE(CS.TotalScore, 0) AS TotalScore,
    COALESCE(CS.AverageScore, 0) AS AverageScore
FROM 
    CombinedStats CS
ORDER BY 
    CS.BadgeCount DESC, 
    CS.TotalScore DESC
LIMIT 100;
