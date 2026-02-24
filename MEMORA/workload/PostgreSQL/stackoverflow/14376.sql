WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
),

UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgUserReputation
    FROM 
        Users
),

VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.AvgPostScore,
    p.TotalViews,
    u.TotalUsers,
    u.AvgUserReputation,
    v.TotalVotes,
    v.TotalUpVotes,
    v.TotalDownVotes
FROM 
    PostStats p,
    UserStats u,
    VoteStats v;