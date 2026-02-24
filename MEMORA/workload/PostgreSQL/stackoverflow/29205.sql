WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostTypeStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPostsByUser,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageUserViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    U.DisplayName,
    U.BadgeCount,
    PTS.PostTypeName,
    PTS.TotalPosts,
    PTS.PositiveScorePosts,
    PTS.AverageViewCount,
    UPS.TotalPostsByUser,
    UPS.TotalScore,
    UPS.AverageUserViewCount
FROM 
    UserBadgeCounts U
JOIN 
    PostTypeStats PTS ON (U.BadgeCount > 0 AND PTS.TotalPosts > 0) 
JOIN 
    UserPostStats UPS ON U.UserId = UPS.UserId
ORDER BY 
    U.BadgeCount DESC, 
    UPS.TotalScore DESC, 
    PTS.TotalPosts DESC;