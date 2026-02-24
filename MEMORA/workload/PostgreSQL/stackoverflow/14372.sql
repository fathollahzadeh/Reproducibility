WITH PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalPostOwners,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM 
        Posts
),
UserStatistics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        MIN(CreationDate) AS EarliestUserCreation,
        MAX(CreationDate) AS LatestUserCreation
    FROM 
        Users
),
VoteStatistics AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
),
CommentStatistics AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
)
SELECT 
    ps.TotalPosts,
    ps.TotalPostOwners,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalClosedPosts,
    us.TotalUsers,
    us.AverageReputation,
    us.EarliestUserCreation,
    us.LatestUserCreation,
    vs.TotalVotes,
    vs.TotalUpVotes,
    vs.TotalDownVotes,
    cs.TotalComments,
    cs.AverageCommentScore
FROM 
    PostStatistics ps,
    UserStatistics us,
    VoteStatistics vs,
    CommentStatistics cs;