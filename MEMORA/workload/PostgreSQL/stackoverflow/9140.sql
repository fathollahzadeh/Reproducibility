WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
TopPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBS.TotalBadges, 0) AS BadgeCount,
        COALESCE(TP.PostCount, 0) AS PostCount,
        COALESCE(TP.TotalScore, 0) AS TotalScore,
        COALESCE(TP.AvgViewCount, 0) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats UBS ON U.Id = UBS.UserId
    LEFT JOIN 
        TopPosts TP ON U.Id = TP.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.PostCount,
    U.TotalScore,
    U.AvgViewCount,
    RANK() OVER (ORDER BY U.TotalScore DESC, U.PostCount DESC) AS Rank
FROM 
    UserPerformance U
ORDER BY 
    Rank
LIMIT 10;