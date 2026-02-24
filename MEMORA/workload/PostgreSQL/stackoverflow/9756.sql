WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT PostId, Title, Score, CreationDate, OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 3
),
PostStats AS (
    SELECT tp.PostId, 
           tp.Title,
           tp.Score,
           tp.CreationDate,
           tp.OwnerDisplayName,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM TopPosts tp
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    GROUP BY tp.PostId, tp.Title, tp.Score, tp.CreationDate, tp.OwnerDisplayName
)
SELECT ps.PostId, 
       ps.Title, 
       ps.Score, 
       ps.CreationDate, 
       ps.OwnerDisplayName, 
       ps.CommentCount, 
       ps.UpVoteCount,
       ps.DownVoteCount,
       pht.Name AS PostHistoryType
FROM PostStats ps
LEFT JOIN PostHistory ph ON ps.PostId = ph.PostId
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
ORDER BY ps.Score DESC, ps.CommentCount DESC;