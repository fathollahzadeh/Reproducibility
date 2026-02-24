WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Name IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.Score > 5
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
    ORDER BY p.ViewCount DESC
    LIMIT 10
),
ActiveUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY u.DisplayName
    HAVING COUNT(p.Id) > 5
)
SELECT 
    us.DisplayName AS UserName,
    us.Reputation,
    us.PostCount,
    us.AnswerCount,
    us.BadgeCount,
    pp.Title AS PopularPostTitle,
    pp.CreationDate AS PopularPostDate,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    au.TotalPosts AS ActiveUserPostCount,
    au.UpvotesReceived AS ActiveUserUpvotes
FROM UserStats us
JOIN PopularPosts pp ON us.UserId = (SELECT OwnerUserId FROM Posts ORDER BY ViewCount DESC LIMIT 1)
JOIN ActiveUsers au ON us.DisplayName = au.DisplayName
ORDER BY us.Reputation DESC, pp.ViewCount DESC;