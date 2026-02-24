WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.CreationDate,
           p.ViewCount,
           p.Score,
           p.Tags,
           ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
      AND p.Score > 0
),
SelectedPosts AS (
    SELECT rp.PostId,
           rp.Title,
           rp.Body,
           rp.CreationDate,
           rp.ViewCount,
           rp.Score,
           rp.Tags
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
),
CommentsOnSelectedPosts AS (
    SELECT c.PostId,
           COUNT(c.Id) AS CommentCount
    FROM Comments c
    JOIN SelectedPosts sp ON c.PostId = sp.PostId
    GROUP BY c.PostId
),
UserStats AS (
    SELECT u.Id AS UserId,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON c.UserId = u.Id
    WHERE u.Reputation >= 1000
    GROUP BY u.Id
)
SELECT sp.Title,
       sp.ViewCount,
       sp.Score,
       sp.Tags,
       cs.CommentCount,
       us.UserId,
       us.BadgeCount,
       us.TotalComments
FROM SelectedPosts sp
LEFT JOIN CommentsOnSelectedPosts cs ON sp.PostId = cs.PostId
LEFT JOIN UserStats us ON us.TotalComments > 0
ORDER BY sp.Score DESC, us.BadgeCount DESC;