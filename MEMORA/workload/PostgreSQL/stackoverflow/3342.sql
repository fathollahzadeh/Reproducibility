
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), RankedUsers AS (
    SELECT 
        ue.*,
        ROW_NUMBER() OVER (ORDER BY ue.Reputation DESC) AS Rank
    FROM UserEngagement ue
), TopUsers AS (
    SELECT *
    FROM RankedUsers
    WHERE Rank <= 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalPosts,
    COALESCE(b.TotalBadges, 0) AS BadgeCount,
    CASE 
        WHEN tu.TotalPosts > 0 THEN ROUND((CAST(tu.UpVotes AS numeric) / NULLIF(tu.UpVotes + tu.DownVotes + tu.TotalPosts, 0)) * 100, 2)
        ELSE 0 
    END AS EngagementRate
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
) b ON tu.UserId = b.UserId
ORDER BY tu.Reputation DESC;
