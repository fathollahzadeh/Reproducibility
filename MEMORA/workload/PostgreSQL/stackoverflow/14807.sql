WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers
    FROM 
        Users
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore
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
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
)

SELECT 
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT AvgPostScore FROM PostStats) AS AvgPostScore,
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT TotalUpVotes FROM VoteStats) AS TotalUpVotes,
    (SELECT TotalDownVotes FROM VoteStats) AS TotalDownVotes,
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes;