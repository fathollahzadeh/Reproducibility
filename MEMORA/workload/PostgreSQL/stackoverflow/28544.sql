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
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
BadgePostStats AS (
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
        PS.TotalViews
    FROM 
        UserBadgeCounts UB
    LEFT JOIN 
        PostStatistics PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    B.UserId,
    B.DisplayName,
    B.BadgeCount,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    COALESCE(B.PostCount, 0) AS PostCount,
    COALESCE(B.QuestionCount, 0) AS QuestionCount,
    COALESCE(B.AnswerCount, 0) AS AnswerCount,
    COALESCE(B.TotalViews, 0) AS TotalViews,
    RANK() OVER (ORDER BY B.BadgeCount DESC) AS BadgeRank
FROM 
    BadgePostStats B
ORDER BY 
    BadgeCount DESC, DisplayName;
