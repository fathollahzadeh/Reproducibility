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
        SUM(P.Score) AS TotalScore, 
        SUM(P.ViewCount) AS TotalViews, 
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
FinalStats AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    *
FROM 
    FinalStats
WHERE 
    BadgeCount > 0
ORDER BY 
    TotalScore DESC, BadgeCount DESC;