
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
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
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.PostCount, 0) AS PostCount,
        COALESCE(UB.TotalViews, 0) AS TotalViews,
        COALESCE(UB.AverageScore, 0) AS AverageScore,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostStats UB ON U.Id = UB.OwnerUserId
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    AverageScore,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CASE 
        WHEN PostCount > 50 THEN 'Highly Active'
        WHEN PostCount BETWEEN 21 AND 50 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    UserPostStats
WHERE 
    TotalViews > 1000
ORDER BY 
    TotalViews DESC;
