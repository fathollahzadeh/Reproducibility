WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalAuthors,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgPostScore
    FROM Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM Comments
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM Users
)

SELECT 
    PS.TotalPosts,
    PS.TotalAuthors,
    PS.AvgViewCount,
    PS.AvgPostScore,
    CS.TotalComments,
    CS.AvgCommentScore,
    US.TotalUsers,
    US.AvgReputation
FROM PostStats PS, CommentStats CS, UserStats US;