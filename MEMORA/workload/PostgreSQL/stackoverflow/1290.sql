
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.OwnerUserId,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
UserStatistics AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           SUM(rp.PostRank) AS TotalPostRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT b.Id) > 5
)
SELECT us.UserId,
       us.DisplayName,
       us.Reputation,
       us.BadgeCount,
       COALESCE(MAX(rp.Score), 0) AS MaxPostScore,
       COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
       COALESCE(AVG(rp.UpvoteCount), 0) AS AvgUpvotes,
       COALESCE(AVG(rp.DownvoteCount), 0) AS AvgDownvotes
FROM UserStatistics us
LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
GROUP BY us.UserId, us.DisplayName, us.Reputation, us.BadgeCount
ORDER BY us.Reputation DESC, MaxPostScore DESC
LIMIT 10;
