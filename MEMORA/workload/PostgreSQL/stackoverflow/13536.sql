WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.TotalScore,
    UPS.AvgViewCount,
    UPS.LastPostDate,
    COALESCE(UBS.BadgeCount, 0) AS BadgeCount,
    COALESCE(UBS.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(UBS.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(UBS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadgeStats UBS ON UPS.UserId = UBS.UserId
ORDER BY 
    UPS.TotalScore DESC
LIMIT 10;