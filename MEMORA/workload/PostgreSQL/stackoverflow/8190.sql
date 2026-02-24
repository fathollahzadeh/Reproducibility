
WITH RankedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT u.Id AS UserId, u.DisplayName,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(b.Class) AS TotalBadges,
           SUM(p.ViewCount) AS TotalViews,
           COALESCE(AVG(pp.Score), 0) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN RankedPosts pp ON u.Id = pp.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT us.UserId, us.DisplayName, us.TotalPosts, us.PositivePosts, us.TotalBadges, us.TotalViews, us.AvgPostScore
FROM UserStats us
JOIN (
    SELECT UserId
    FROM UserStats
    WHERE TotalPosts > 10
    ORDER BY AvgPostScore DESC
    LIMIT 5
) top_users ON us.UserId = top_users.UserId
ORDER BY us.TotalViews DESC;
