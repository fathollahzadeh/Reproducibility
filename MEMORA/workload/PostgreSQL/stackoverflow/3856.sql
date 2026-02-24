
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           SUM(p.ViewCount) AS TotalViews,
           COUNT(bp.Id) AS BadgeCount,
           AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges bp ON u.Id = bp.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
MostCommentedPosts AS (
    SELECT p.Id, p.Title, COUNT(c.Id) AS TotalComments
    FROM Posts p
    JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title
    HAVING COUNT(c.Id) > 10
)
SELECT u.DisplayName, us.TotalViews, us.BadgeCount, us.AvgReputation,
       rp.Title AS RecentPostTitle, rp.ViewCount AS RecentPostViews,
       COALESCE(mcp.TotalComments, 0) AS CommentCountOnMostCommented
FROM UserStats us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN RecentPosts rp ON u.Id = rp.Id AND rp.RN = 1
LEFT JOIN MostCommentedPosts mcp ON rp.Id = mcp.Id
WHERE us.TotalViews > 5000
ORDER BY us.AvgReputation DESC, us.BadgeCount DESC
LIMIT 10;
