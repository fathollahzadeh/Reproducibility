WITH PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.FavoriteCount) AS TotalFavorites
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserStatistics AS (
    SELECT 
        U.DisplayName AS UserName,
        COUNT(P.Id) AS TotalPosts,
        AVG(U.Reputation) AS AvgReputation,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    PS.PostType,
    PS.TotalPosts,
    PS.AvgScore,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.TotalComments,
    PS.TotalFavorites,
    US.UserName,
    US.TotalPosts AS UserTotalPosts,
    US.AvgReputation,
    US.TotalViews AS UserTotalViews
FROM 
    PostStatistics PS
LEFT JOIN 
    UserStatistics US ON US.TotalPosts > 0
ORDER BY 
    PS.TotalPosts DESC, US.TotalPosts DESC;