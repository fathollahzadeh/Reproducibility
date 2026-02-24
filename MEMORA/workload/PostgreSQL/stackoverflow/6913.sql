WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(a.VoteCount, 0)) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) a ON p.Id = a.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.TotalViews,
        ue.TotalUpVotes,
        ue.TotalPosts,
        ue.TotalComments,
        ue.TotalBadges,
        ROW_NUMBER() OVER (ORDER BY ue.TotalViews DESC, ue.TotalUpVotes DESC) AS Rank
    FROM UserEngagement ue
)
SELECT 
    u.DisplayName,
    tu.TotalViews,
    tu.TotalUpVotes,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBadges
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
WHERE tu.Rank <= 10
ORDER BY tu.TotalViews DESC, tu.TotalUpVotes DESC;
