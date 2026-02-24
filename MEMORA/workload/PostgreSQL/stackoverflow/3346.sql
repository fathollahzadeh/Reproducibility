
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalViews,
        ua.TotalUpVotes - ua.TotalDownVotes AS VoteBalance,
        RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
    FROM UserActivity ua
    WHERE ua.PostCount > 5
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.VoteBalance,
    CASE 
        WHEN tu.ViewRank <= 10 THEN 'Top Contributor'
        WHEN tu.ViewRank <= 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel,
    COALESCE(tu.TotalViews / NULLIF(tu.PostCount, 0), 0) AS AvgViewsPerPost
FROM TopUsers tu
WHERE tu.VoteBalance > 0
ORDER BY tu.TotalViews DESC
LIMIT 20;
