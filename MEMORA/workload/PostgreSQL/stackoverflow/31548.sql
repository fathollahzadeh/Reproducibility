WITH RECURSIVE UserBadges AS (
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
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PM.QuestionCount, 0) AS QuestionCount,
        COALESCE(PM.AnswerCount, 0) AS AnswerCount,
        COALESCE(PM.TotalScore, 0) AS TotalScore,
        COALESCE(PM.TotalViews, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostMetrics PM ON U.Id = PM.OwnerUserId
),
RankedUsers AS (
    SELECT 
        US.*,
        RANK() OVER (ORDER BY US.BadgeCount DESC, US.TotalScore DESC, US.TotalViews DESC) AS UserRank
    FROM 
        UserStats US
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.BadgeCount,
    RU.QuestionCount,
    RU.AnswerCount,
    RU.TotalScore,
    RU.TotalViews,
    RU.UserRank,
    COALESCE(NULLIF(UB.GoldBadges, 0), NULL) AS GoldBadgeIndicator,
    COALESCE(NULLIF(UB.SilverBadges, 0), NULL) AS SilverBadgeIndicator,
    COALESCE(NULLIF(UB.BronzeBadges, 0), NULL) AS BronzeBadgeIndicator
FROM 
    RankedUsers RU
LEFT JOIN 
    UserBadges UB ON RU.UserId = UB.UserId
WHERE 
    RU.UserRank <= 10 
ORDER BY 
    RU.UserRank;