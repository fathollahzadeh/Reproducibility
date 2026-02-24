
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
UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
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
        COALESCE(UP.PostCount, 0) AS PostCount,
        COALESCE(UP.TotalScore, 0) AS TotalScore,
        COALESCE(UP.AverageViews, 0) AS AverageViews
    FROM 
        UserBadges UB
    LEFT JOIN 
        UserPosts UP ON UB.UserId = UP.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalScore,
    AverageViews
FROM 
    CombinedStats
ORDER BY 
    TotalScore DESC, BadgeCount DESC
LIMIT 10;
