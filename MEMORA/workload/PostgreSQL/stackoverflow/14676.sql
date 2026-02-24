WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsByUsers,
        SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS ScoredPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
),
VoteStats AS (
    SELECT 
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PostsByUsers,
    ps.ScoredPosts,
    us.TotalUsers,
    us.TotalReputation,
    vs.TotalVotes,
    vs.UpVotes,
    vs.DownVotes
FROM 
    PostStats ps,
    UserStats us,
    VoteStats vs
ORDER BY 
    ps.TotalPosts DESC;