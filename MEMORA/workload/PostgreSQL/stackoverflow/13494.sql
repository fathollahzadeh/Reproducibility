WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.ViewCount) AS AvgViewsPerPost,
        COUNT(COALESCE(C.Id, NULL)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    TotalViews,
    AvgViewsPerPost,
    TotalComments
FROM 
    UserPostStats
ORDER BY 
    Reputation DESC, TotalPosts DESC;