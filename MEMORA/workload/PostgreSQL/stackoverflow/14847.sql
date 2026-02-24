
WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate))) AS AvgUserAgeInSeconds
    FROM 
        Users
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate))) AS AvgPostAgeInSeconds
    FROM 
        Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
)

SELECT 
    u.TotalUsers,
    u.AvgUserAgeInSeconds,
    p.TotalPosts,
    p.AvgPostAgeInSeconds,
    c.TotalComments,
    v.TotalVotes
FROM 
    UserStats u,
    PostStats p,
    CommentStats c,
    VoteStats v;
