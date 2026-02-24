WITH PostMetrics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.ViewCount) AS AvgViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    ORDER BY 
        U.Reputation DESC
    LIMIT 5
)

SELECT 
    PM.PostType,
    PM.PostCount,
    PM.AvgViews,
    PM.AvgScore,
    TU.DisplayName AS TopUser,
    TU.Reputation,
    TU.TotalPosts
FROM 
    PostMetrics PM
CROSS JOIN 
    TopUsers TU
ORDER BY 
    PM.PostCount DESC;