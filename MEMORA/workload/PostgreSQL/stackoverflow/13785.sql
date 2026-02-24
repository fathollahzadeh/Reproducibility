WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore
    FROM 
        Posts
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgUserReputation
    FROM 
        Users
)
SELECT 
    p.TotalPosts,
    c.TotalComments,
    u.TotalUsers,
    p.AvgPostScore,
    u.AvgUserReputation
FROM 
    PostCounts p,
    CommentCounts c,
    UserStats u;