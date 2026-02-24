WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        SUM(Score) AS TotalPostScore,
        AVG(Score) AS AveragePostScore
    FROM 
        Posts
),
VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
)
SELECT 
    p.TotalPosts,
    p.TotalUsers,
    p.TotalPostScore,
    p.AveragePostScore,
    v.TotalVotes,
    v.TotalUpVotes,
    v.TotalDownVotes
FROM 
    PostCounts p, 
    VoteCounts v;