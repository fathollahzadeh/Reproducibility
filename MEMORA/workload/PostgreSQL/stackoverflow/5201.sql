WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN P.PostTypeId = 3 THEN 1 END) AS WikiCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UBadge.BadgeCount,
    UBadge.GoldBadges,
    UBadge.SilverBadges,
    UBadge.BronzeBadges,
    PStat.QuestionCount,
    PStat.AnswerCount,
    PStat.WikiCount,
    PStat.TotalScore
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBadge ON U.Id = UBadge.UserId
LEFT JOIN 
    PostStatistics PStat ON U.Id = PStat.OwnerUserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    UBadge.BadgeCount DESC;
