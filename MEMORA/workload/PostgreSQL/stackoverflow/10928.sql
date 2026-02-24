WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.DisplayName
    ORDER BY PostsCreated DESC
    LIMIT 10
),
VoteStats AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY vt.Name
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgScore,
    ps.TotalViews,
    ps.TotalAnswers,
    tu.DisplayName AS TopUser,
    tu.PostsCreated,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.AvgReputation,
    vs.VoteType,
    vs.TotalVotes,
    vs.UpVotes,
    vs.DownVotes
FROM PostStats ps
CROSS JOIN TopUsers tu
CROSS JOIN VoteStats vs
ORDER BY ps.TotalPosts DESC;