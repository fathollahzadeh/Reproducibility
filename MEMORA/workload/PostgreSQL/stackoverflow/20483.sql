WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN B.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PS.PostCount,
        PS.TotalScore,
        PS.AvgViewCount,
        PS.LatestPostDate,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PS.TotalScore DESC NULLS LAST) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UP.PostCount, 0) AS NumberOfPosts,
    COALESCE(UP.TotalScore, 0) AS TotalScore,
    COALESCE(UP.AvgViewCount, 0) AS AverageViewCount,
    COALESCE(UP.BadgeCount, 0) AS TotalBadges,
    COALESCE(UP.GoldBadges, 0) AS GoldBadges,
    COALESCE(UP.SilverBadges, 0) AS SilverBadges,
    COALESCE(UP.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN UP.ScoreRank IS NULL THEN 'No Posts'
        ELSE CAST(UP.ScoreRank AS VARCHAR)
    END AS Rank
FROM 
    Users U
LEFT JOIN 
    UserPosts UP ON U.Id = UP.UserId
WHERE 
    U.LastAccessDate > cast('2024-10-01' as date) - INTERVAL '6 months'
ORDER BY 
    TotalScore DESC NULLS LAST, 
    NumberOfPosts DESC, 
    DisplayName;