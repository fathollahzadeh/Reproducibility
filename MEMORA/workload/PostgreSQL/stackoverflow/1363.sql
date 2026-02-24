WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
BadgesSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
HighlyActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalScore,
        UA.TotalAnswers,
        COALESCE(BG.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BR.BronzeBadges, 0) AS BronzeBadges,
        UA.LastPostDate
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgesSummary BG ON UA.UserId = BG.UserId
    LEFT JOIN 
        BadgesSummary BS ON UA.UserId = BS.UserId
    LEFT JOIN 
        BadgesSummary BR ON UA.UserId = BR.UserId
    WHERE 
        UA.TotalScore > 5000 OR UA.TotalAnswers > 20
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalAnswers,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    LastPostDate
FROM 
    HighlyActiveUsers
WHERE 
    LastPostDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
ORDER BY 
    TotalScore DESC, PostCount DESC
LIMIT 10;