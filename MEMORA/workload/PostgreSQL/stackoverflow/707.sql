
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.PostCount,
        ua.TotalViews,
        (ua.UpVotes - ua.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY ua.PostCount DESC, ua.TotalViews DESC) AS Rank
    FROM UserActivity ua
)
SELECT 
    tu.UserId,
    u.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.NetVotes,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        WHEN tu.Rank <= 50 THEN 'Average Contributor'
        ELSE 'Needs Improvement'
    END AS ContributorLevel
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
WHERE tu.PostCount > 0
  AND EXISTS (
      SELECT 1 
      FROM Posts p 
      WHERE p.OwnerUserId = u.Id AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
  )
ORDER BY tu.Rank;
