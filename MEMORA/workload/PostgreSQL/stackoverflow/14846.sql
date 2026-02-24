
WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(U.Reputation) AS TotalReputation,
        AVG(U.Views) AS AvgUserViews,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostTypeId,
    PS.TotalPosts,
    PS.TotalViews,
    PS.AvgScore,
    PS.LastPostDate,
    COUNT(DISTINCT US.UserId) AS ActiveUsers,
    SUM(US.PostsCreated) AS TotalPostsByUsers,
    SUM(US.TotalReputation) AS TotalReputationByUsers,
    AVG(US.AvgUserViews) AS AvgUserViewsByUsers,
    SUM(US.TotalBadges) AS TotalBadgesByUsers
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.TotalPosts > 0
GROUP BY 
    PS.PostTypeId, PS.TotalPosts, PS.TotalViews, PS.AvgScore, PS.LastPostDate
ORDER BY 
    PS.PostTypeId;
