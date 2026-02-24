WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis
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
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
),
BadgeStats AS (
    SELECT 
        COUNT(*) AS TotalBadges
    FROM 
        Badges
)

SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT TotalQuestions FROM PostStats) AS TotalQuestions,
    (SELECT TotalAnswers FROM PostStats) AS TotalAnswers,
    (SELECT TotalTagWikis FROM PostStats) AS TotalTagWikis,
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes,
    (SELECT TotalUpVotes FROM VoteStats) AS TotalUpVotes,
    (SELECT TotalDownVotes FROM VoteStats) AS TotalDownVotes,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AvgReputation FROM UserStats) AS AvgReputation,
    (SELECT TotalBadges FROM BadgeStats) AS TotalBadges;