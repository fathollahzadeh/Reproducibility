WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, TotalPosts DESC) AS Rank
    FROM UserScores
)
SELECT 
    tu.DisplayName,
    tu.NetVotes,
    tu.TotalPosts,
    tu.TotalComments,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        WHEN tu.Rank <= 50 THEN 'Prolific Contributor'
        ELSE 'New Contributor'
    END AS ContributorRating
FROM TopUsers tu
WHERE tu.Rank <= 100
ORDER BY tu.Rank;
