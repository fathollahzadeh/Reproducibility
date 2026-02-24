
WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(P.FavoriteCount, 0)) AS TotalFavorites,
        MAX(P.CreationDate) AS LatestPostDate
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
        MAX(U.LastAccessDate) AS LastActivity
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
    PS.AvgScore,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.TotalComments,
    PS.TotalFavorites,
    PS.LatestPostDate,
    US.DisplayName AS TopUser,
    US.TotalBadges,
    US.TotalReputation,
    US.LastActivity
FROM 
    PostStats PS
JOIN 
    UserStats US ON US.TotalBadges = (SELECT MAX(TotalBadges) FROM UserStats)
ORDER BY 
    PS.TotalPosts DESC;
