
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
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        PS.PostCount,
        PS.TotalScore,
        PS.TotalViews,
        RANK() OVER (ORDER BY PS.TotalScore DESC) AS ScoreRank
    FROM 
        UserBadges UB
    JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    RU.DisplayName,
    RU.PostCount,
    RU.TotalScore,
    RU.TotalViews,
    RU.ScoreRank,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
FROM 
    RankedUsers RU
LEFT JOIN 
    UserBadges UB ON RU.UserId = UB.UserId
ORDER BY 
    RU.ScoreRank;
