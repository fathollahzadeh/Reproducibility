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
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.AcceptedAnswers, 0) AS AcceptedAnswers,
        COALESCE(P.AvgScore, 0) AS AvgScore,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.TotalPosts,
    A.AcceptedAnswers,
    A.AvgScore,
    A.TotalViews,
    A.BadgeCount
FROM 
    ActiveUsers A
ORDER BY 
    A.TotalPosts DESC, 
    A.AcceptedAnswers DESC, 
    A.AvgScore DESC
LIMIT 10;
