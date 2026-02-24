
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
), PostsAggregated AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
), UsersWithPostsAndBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PA.PostCount, 0) AS TotalPosts,
        COALESCE(PA.TotalScore, 0) AS TotalPostScore,
        COALESCE(PA.LastPostDate, '1970-01-01 00:00:00') AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostsAggregated PA ON U.Id = PA.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    CASE WHEN U.TotalPosts > 0 
         THEN COALESCE(U.TotalPostScore / NULLIF(U.TotalPosts, 0), 0) 
         ELSE 0 END AS AveragePostScore,
    U.TotalBadges,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    CASE WHEN U.LastPostDate = '1970-01-01 00:00:00' THEN NULL 
         ELSE U.LastPostDate END AS LastActiveDate,
    CASE 
        WHEN U.TotalBadges = 0 THEN 'Novice'
        WHEN U.TotalBadges BETWEEN 1 AND 5 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    UsersWithPostsAndBadges U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    AveragePostScore DESC 
LIMIT 50;
