WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM 
        Posts
),

UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation > 0 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM 
        Users
),

CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),

VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.UniquePostOwners,
    u.TotalUsers,
    u.ActiveUsers,
    c.TotalComments,
    v.TotalVotes
FROM 
    PostCounts p,
    UserCounts u,
    CommentCounts c,
    VoteCounts v;