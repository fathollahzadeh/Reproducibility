WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
VoteCounts AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    pc.AverageScore,
    vc.VoteType,
    vc.TotalVotes,
    us.TotalUsers,
    us.AverageReputation
FROM 
    PostCounts pc
CROSS JOIN 
    UserStats us
CROSS JOIN 
    VoteCounts vc
ORDER BY 
    pc.TotalPosts DESC;