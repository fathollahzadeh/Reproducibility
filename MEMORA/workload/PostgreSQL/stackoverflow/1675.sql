WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.Upvotes,
        ua.Downvotes,
        pp.Title AS TopPostTitle,
        pp.ViewCount AS TopPostViews
    FROM UserActivity ua
    LEFT JOIN PopularPosts pp ON ua.VoteRank = 1
    WHERE ua.Reputation >= 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.Upvotes,
    tu.Downvotes,
    COALESCE(tu.TopPostTitle, 'No posts') AS TopPostTitle,
    COALESCE(tu.TopPostViews, 0) AS TopPostViews
FROM TopUsers tu
ORDER BY tu.Reputation DESC, tu.Upvotes DESC
LIMIT 10;