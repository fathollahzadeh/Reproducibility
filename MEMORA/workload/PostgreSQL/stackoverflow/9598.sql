
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), PostDetails AS (
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
), CombinedData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(UB.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadgeCount,
        COALESCE(PD.QuestionCount, 0) AS QuestionCount,
        COALESCE(PD.AnswerCount, 0) AS AnswerCount,
        COALESCE(PD.TotalScore, 0) AS TotalScore,
        COALESCE(PD.TotalViews, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostDetails PD ON U.Id = PD.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews
FROM 
    CombinedData
ORDER BY 
    TotalScore DESC, BadgeCount DESC, DisplayName ASC
FETCH FIRST 100 ROWS ONLY;
