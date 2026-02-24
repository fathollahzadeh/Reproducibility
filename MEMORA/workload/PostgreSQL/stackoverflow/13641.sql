WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(DISTINCT u.Id) AS UserCount,
        AVG(u.Reputation) AS AvgReputation,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
)
SELECT 
    ps.PostTypeName,
    ps.PostCount,
    ps.AvgScore,
    us.UserCount,
    us.AvgReputation,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps,
    UserStats us
ORDER BY 
    ps.PostCount DESC;