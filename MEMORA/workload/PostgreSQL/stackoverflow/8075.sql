WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
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
        COUNT(P.Id) AS TotalPosts,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        Coalesce(UB.BadgeCount, 0) AS BadgeCount,
        Coalesce(PS.TotalPosts, 0) AS TotalPosts,
        Coalesce(PS.TotalAnswers, 0) AS TotalAnswers,
        Coalesce(PS.TotalViews, 0) AS TotalViews,
        Coalesce(PS.AverageScore, 0) AS AverageScore,
        Coalesce(PS.LatestPostDate, '1900-01-01') AS LatestPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    TotalAnswers,
    TotalViews,
    AverageScore,
    LatestPostDate
FROM 
    UserPerformance
WHERE 
    BadgeCount > 0 OR TotalPosts > 5
ORDER BY 
    TotalViews DESC, AverageScore DESC;
