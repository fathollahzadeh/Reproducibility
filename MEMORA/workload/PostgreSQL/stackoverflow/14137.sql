WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalPostOwners,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswersPerQuestion
    FROM 
        Posts
), UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        SUM(CASE WHEN Views IS NOT NULL THEN Views ELSE 0 END) AS TotalViews,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        Users
), VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN VoteTypeId = 6 THEN 1 ELSE 0 END) AS TotalCloseVotes,
        SUM(CASE WHEN VoteTypeId = 11 THEN 1 ELSE 0 END) AS TotalUndeletionVotes
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.TotalPostOwners,
    p.TotalQuestions,
    p.TotalAnswers,
    p.TotalTagWikis,
    p.AvgViews,
    p.AvgScore,
    p.AvgAnswersPerQuestion,
    u.TotalUsers,
    u.AvgReputation,
    u.TotalViews AS UserTotalViews,
    u.TotalUpVotes,
    u.TotalDownVotes,
    v.TotalVotes,
    v.TotalUpVotes AS VoteTotalUpVotes,
    v.TotalDownVotes AS VoteTotalDownVotes,
    v.TotalCloseVotes,
    v.TotalUndeletionVotes
FROM 
    PostStats p,
    UserStats u,
    VoteStats v;