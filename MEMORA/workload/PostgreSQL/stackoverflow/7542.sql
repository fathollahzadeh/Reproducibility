
WITH RankedVotes AS (
    SELECT p.Id AS PostId, 
           v.VoteTypeId, 
           COUNT(v.Id) AS VoteCount,
           ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, v.VoteTypeId
),
TopPosts AS (
    SELECT p.Id, 
           p.Title, 
           SUM(CASE WHEN rv.VoteTypeId = 2 THEN rv.VoteCount ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN rv.VoteTypeId = 3 THEN rv.VoteCount ELSE 0 END) AS Downvotes,
           COUNT(c.Id) AS CommentCount,
           COUNT(b.Id) AS BadgeCount,
           p.CreationDate,
           p.ViewCount
    FROM Posts p
    LEFT JOIN RankedVotes rv ON p.Id = rv.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
    HAVING COUNT(c.Id) > 5
    ORDER BY Upvotes DESC 
    LIMIT 10
)
SELECT tp.Title, 
       tp.Upvotes, 
       tp.Downvotes, 
       tp.CommentCount, 
       tp.BadgeCount, 
       tp.ViewCount, 
       EXTRACT(YEAR FROM tp.CreationDate) AS CreationYear
FROM TopPosts tp
ORDER BY tp.Upvotes DESC, tp.CreationDate DESC;
