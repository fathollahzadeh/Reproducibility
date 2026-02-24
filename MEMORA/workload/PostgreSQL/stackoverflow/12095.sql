WITH PostMetrics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AveragePostScore,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments,
        SUM(FavoriteCount) AS TotalFavorites
    FROM 
        Posts
),
UserMetrics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        Users
)

SELECT 
    PM.TotalPosts,
    PM.AveragePostScore,
    PM.TotalViews,
    PM.TotalAnswers,
    PM.TotalComments,
    PM.TotalFavorites,
    UM.TotalUsers,
    UM.AverageReputation,
    UM.TotalUpVotes,
    UM.TotalDownVotes
FROM 
    PostMetrics PM, UserMetrics UM;