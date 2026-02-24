
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT PostId, Title, CreationDate, Score, CommentCount, UpvoteCount, DownvoteCount
    FROM RankedPosts
    WHERE Rank <= 10
)
SELECT t.Title,
       t.CreationDate,
       t.Score,
       t.CommentCount,
       t.UpvoteCount,
       t.DownvoteCount,
       u.DisplayName AS OwnerDisplayName,
       b.Name AS BadgeName
FROM TopPosts t
JOIN Users u ON t.PostId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE b.Class = 1 OR b.Class = 2 
ORDER BY t.Score DESC, t.CommentCount DESC;
