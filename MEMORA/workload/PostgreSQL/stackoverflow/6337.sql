WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionsCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswersCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END, 0)) AS WikisCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
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
FinalReport AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalViews,
        UA.TotalScore,
        UA.QuestionsCount,
        UA.AnswersCount,
        UA.WikisCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserActivity UA
    LEFT JOIN 
        UserBadges UB ON UA.UserId = UB.UserId
)
SELECT 
    FR.DisplayName,
    FR.PostCount,
    FR.TotalViews,
    FR.TotalScore,
    FR.QuestionsCount,
    FR.AnswersCount,
    FR.WikisCount,
    FR.GoldBadges,
    FR.SilverBadges,
    FR.BronzeBadges
FROM 
    FinalReport FR
ORDER BY 
    FR.TotalScore DESC, FR.PostCount DESC
LIMIT 20;
