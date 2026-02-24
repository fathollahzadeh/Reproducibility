WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostMetrics AS (
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
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PM.PostCount, 0) AS PostCount,
        COALESCE(PM.TotalScore, 0) AS TotalScore,
        COALESCE(PM.AvgViewCount, 0) AS AvgViewCount,
        RANK() OVER (ORDER BY COALESCE(PM.TotalScore, 0) DESC, COALESCE(UB.BadgeCount, 0) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostMetrics PM ON U.Id = PM.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.PostCount,
    U.TotalScore,
    U.AvgViewCount,
    CASE 
        WHEN U.BadgeCount > 10 THEN 'Expert'
        WHEN U.BadgeCount > 5 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel,
    CASE 
        WHEN U.TotalScore > 1000 THEN 'High Engagement'
        WHEN U.TotalScore BETWEEN 500 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopUsers U
WHERE 
    U.UserRank <= 50
ORDER BY 
    U.UserRank ASC;