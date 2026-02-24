
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.CreationDate, 
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT b.Id) AS BadgeCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.OwnerDisplayName, rp.CommentCount, rp.BadgeCount
    FROM RankedPosts rp
    WHERE rp.Rank <= 3
)
SELECT tp.Title, 
       tp.Score, 
       tp.CreationDate, 
       tp.OwnerDisplayName, 
       tp.CommentCount, 
       CASE 
           WHEN tp.BadgeCount >= 5 THEN 'Gold'
           WHEN tp.BadgeCount BETWEEN 3 AND 4 THEN 'Silver'
           ELSE 'Bronze'
       END AS BadgeTier
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.CreationDate DESC;
