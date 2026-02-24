WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
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
        AVG(Reputation) AS AvgUserReputation
    FROM Users
)

SELECT 
    p.TotalPosts,
    p.AvgPostScore,
    p.UniquePostOwners,
    c.TotalComments,
    c.AvgCommentScore,
    u.TotalUsers,
    u.AvgUserReputation
FROM 
    PostStats p,
    CommentStats c,
    UserStats u;