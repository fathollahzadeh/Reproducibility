WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalPostOwners,
        COUNT(DISTINCT Id) FILTER (WHERE PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT Id) FILTER (WHERE PostTypeId = 2) AS TotalAnswers,
        COUNT(DISTINCT Id) FILTER (WHERE PostTypeId IN (4, 5)) AS TotalTagWikis
    FROM 
        Posts
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        AVG(Reputation) AS AvgReputation
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
    p.TotalPostOwners,
    p.TotalQuestions,
    p.TotalAnswers,
    p.TotalTagWikis,
    u.TotalUsers,
    u.TotalReputation,
    u.AvgReputation,
    c.TotalComments,
    v.TotalVotes
FROM 
    PostCounts p,
    UserCounts u,
    CommentCounts c,
    VoteCounts v;