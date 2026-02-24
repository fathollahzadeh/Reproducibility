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
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.OwnerUserId IS NOT NULL
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        U.DisplayName,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.PostCount,
        P.TotalViews,
        P.TotalScore,
        P.AvgScore
    FROM 
        UserBadges U
    JOIN 
        PostStats P ON U.UserId = P.OwnerUserId
)

SELECT 
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalViews,
    TotalScore,
    AvgScore
FROM 
    UserPostBadgeStats
WHERE 
    BadgeCount > 0 AND PostCount > 10
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;
