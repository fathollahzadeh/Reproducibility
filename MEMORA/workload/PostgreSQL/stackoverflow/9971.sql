
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.OwnerUserId, 
           p.CreationDate, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT PostId, 
           Title, 
           OwnerUserId, 
           CreationDate, 
           CommentCount, 
           UpvoteCount
    FROM RankedPosts
    WHERE rn = 1
    ORDER BY UpvoteCount DESC
    LIMIT 10
)
SELECT up.DisplayName AS OwnerName, 
       tp.Title, 
       tp.CommentCount, 
       tp.UpvoteCount, 
       tp.CreationDate
FROM TopPosts tp
JOIN Users up ON tp.OwnerUserId = up.Id
ORDER BY tp.UpvoteCount DESC, tp.CreationDate ASC;
