
WITH RankedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.ViewCount, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn,
           u.DisplayName AS UserName, 
           COALESCE(b.Class, 0) AS UserBadgeClass
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.UserName, 
           rp.UserBadgeClass
    FROM RankedPosts rp
    WHERE rp.rn = 1
)
SELECT t.Title, t.UserName, t.UserBadgeClass, t.ViewCount, t.Score, 
       COUNT(c.Id) AS CommentCount, 
       COUNT(ph.Id) AS EditHistoryCount
FROM TopRankedPosts t
LEFT JOIN Comments c ON c.PostId = t.PostId
LEFT JOIN PostHistory ph ON ph.PostId = t.PostId
WHERE t.UserBadgeClass = 1
GROUP BY t.Title, t.UserName, t.UserBadgeClass, t.ViewCount, t.Score
ORDER BY t.Score DESC, t.ViewCount DESC;
