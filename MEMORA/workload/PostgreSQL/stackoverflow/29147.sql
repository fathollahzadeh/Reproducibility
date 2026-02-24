WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users AS U
    LEFT JOIN 
        Badges AS B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts AS P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldCount, 0) AS GoldCount,
        COALESCE(UB.SilverCount, 0) AS SilverCount,
        COALESCE(UB.BronzeCount, 0) AS BronzeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore
    FROM 
        Users AS U
    LEFT JOIN 
        UserBadgeStats AS UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats AS PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.BadgeCount,
    UP.GoldCount,
    UP.SilverCount,
    UP.BronzeCount,
    UP.TotalPosts,
    UP.QuestionCount,
    UP.AnswerCount,
    UP.TotalScore,
    CASE 
        WHEN UP.BadgeCount > 5 AND UP.QuestionCount > 10 THEN 'High Performer'
        WHEN UP.BadgeCount > 2 AND UP.QuestionCount > 5 THEN 'Moderate Performer'
        ELSE 'Beginner'
    END AS PerformanceType
FROM 
    UserPerformance AS UP
ORDER BY 
    UP.TotalScore DESC, UP.BadgeCount DESC
LIMIT 10;
