WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostAnalytics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.Questions, 0) AS Questions,
        COALESCE(PA.Answers, 0) AS Answers,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(PA.AverageScore, 0) AS AverageScore,
        COALESCE(PA.LastPostDate, '1970-01-01') AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCount UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostAnalytics PA ON U.Id = PA.OwnerUserId
)
SELECT 
    UP.DisplayName,
    UP.BadgeCount,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UP.TotalViews,
    UP.AverageScore,
    UP.LastPostDate,
    CASE 
        WHEN UP.TotalPosts > 10 THEN 'Active'
        WHEN UP.TotalPosts BETWEEN 1 AND 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS ActivityLevel
FROM 
    UserPerformance UP
WHERE 
    UP.BadgeCount > 0 OR UP.TotalPosts > 0
ORDER BY 
    UP.BadgeCount DESC, 
    UP.TotalPosts DESC
LIMIT 100;
