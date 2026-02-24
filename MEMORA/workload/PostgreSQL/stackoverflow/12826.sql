WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalPostScore,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgPostScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.TotalPostScore,
    U.BadgeCount,
    COALESCE(P.TotalPosts, 0) AS TotalPosts,
    COALESCE(P.AvgPostScore, 0) AS AvgPostScore,
    COALESCE(P.TotalViews, 0) AS TotalViews
FROM 
    UserStats U
LEFT JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, 
    U.TotalPostScore DESC;