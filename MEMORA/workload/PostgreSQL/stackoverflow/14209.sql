WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) / NULLIF(COUNT(P.Id), 0) AS ScorePerPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.Id,
    U.DisplayName,
    UPS.PostCount,
    UPS.Questions,
    UPS.Answers,
    UPS.Wikis,
    UPS.AverageScore,
    UPS.TotalViews,
    UBS.BadgeCount,
    UBS.GoldBadges,
    UBS.SilverBadges,
    UBS.BronzeBadges,
    UPS.ScorePerPost
FROM 
    Users U
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN 
    UserBadgeStats UBS ON U.Id = UBS.UserId
ORDER BY 
    UPS.PostCount DESC, UPS.AverageScore DESC;