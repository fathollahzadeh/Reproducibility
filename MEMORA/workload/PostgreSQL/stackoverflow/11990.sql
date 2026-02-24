WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AveragePostScore,
        AVG(ViewCount) AS AverageViewCount
    FROM 
        Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageUserReputation
    FROM 
        Users
)

SELECT 
    PS.TotalPosts,
    PS.AveragePostScore,
    PS.AverageViewCount,
    CS.TotalComments,
    CS.AverageCommentScore,
    US.TotalUsers,
    US.AverageUserReputation
FROM 
    PostStats PS, 
    CommentStats CS, 
    UserStats US;