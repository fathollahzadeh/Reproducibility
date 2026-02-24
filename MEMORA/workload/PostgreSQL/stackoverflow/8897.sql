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
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
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
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalScore,
        PS.TotalViews
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews,
    RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
FROM 
    CombinedStats
WHERE 
    BadgeCount > 0 OR PostCount > 0
ORDER BY 
    ScoreRank
LIMIT 100;
