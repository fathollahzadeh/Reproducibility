
WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        PS.LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    CS.DisplayName,
    CS.BadgeCount,
    CS.PostCount,
    CS.TotalAnswers,
    CS.AverageScore,
    CS.LastPostDate,
    CASE 
        WHEN CS.AverageScore IS NULL THEN 'No Posts Yet' 
        WHEN CS.AverageScore > 10 THEN 'High Performer'
        ELSE 'Needs Improvement' 
    END AS PerformanceTier
FROM 
    CombinedStats CS
WHERE 
    CS.BadgeCount > 0 
    OR CS.PostCount > 0
ORDER BY 
    CS.AverageScore DESC, 
    CS.BadgeCount DESC;
