
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

HighReputationUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounty,
        ua.UpVotes,
        ua.DownVotes,
        ua.TotalViews,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM UserActivity ua
    JOIN Users u ON ua.UserId = u.Id
    WHERE u.Reputation > 1000
)

SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalBounty,
    u.UpVotes,
    u.DownVotes,
    u.TotalViews
FROM HighReputationUsers u
WHERE u.Rank <= 10
ORDER BY u.UpVotes DESC, u.TotalPosts DESC;
