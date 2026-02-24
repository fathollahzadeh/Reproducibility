WITH PostStats AS (
    SELECT 
        P.OwnerUserId,
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewPosts,
        AVG(P.ViewCount) AS AvgViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        P.OwnerUserId, PT.Name
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        COALESCE(SUM(P.TotalPosts), 0) AS TotalPosts,
        COALESCE(SUM(P.PositivePosts), 0) AS PositivePosts,
        COALESCE(SUM(P.HighViewPosts), 0) AS HighViewPosts,
        COALESCE(AVG(P.AvgViews), 0) AS AvgViews,
        COALESCE(AVG(P.AvgScore), 0) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    PositivePosts,
    HighViewPosts,
    AvgViews,
    AvgScore
FROM 
    UserStats
ORDER BY 
    Reputation DESC, TotalPosts DESC;