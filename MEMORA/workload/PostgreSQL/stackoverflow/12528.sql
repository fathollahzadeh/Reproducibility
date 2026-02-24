WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        COUNT(DISTINCT P.OwnerUserId) AS TotalUsers
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserStats AS (
    SELECT 
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.Reputation) AS TotalReputation,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    PS.PostType,
    PS.TotalPosts,
    PS.TotalViews,
    PS.TotalScore,
    PS.AverageScore,
    PS.TotalUsers,
    US.DisplayName,
    US.TotalBadges,
    US.TotalReputation,
    US.AverageReputation
FROM 
    PostStats PS
LEFT JOIN 
    UserStats US ON US.TotalReputation = (
        SELECT 
            MAX(TotalReputation) 
        FROM 
            UserStats
    )
ORDER BY 
    PS.TotalPosts DESC;