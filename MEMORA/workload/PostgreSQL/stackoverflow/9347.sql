
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, u.DisplayName AS OwnerDisplayName,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS OwnerPostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT Id, Title, CreationDate, OwnerDisplayName, UpVotes, DownVotes, CommentCount, CloseCount
    FROM RankedPosts
    WHERE OwnerPostRank <= 5
),
ClosingReasons AS (
    SELECT ph.PostId, STRING_AGG(cr.Name, ', ') AS Reasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS integer) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT tp.Title, tp.OwnerDisplayName, tp.UpVotes, tp.DownVotes, tp.CommentCount, 
       COALESCE(cr.Reasons, 'No close reasons') AS CloseReasons
FROM TopPosts tp
LEFT JOIN ClosingReasons cr ON tp.Id = cr.PostId
ORDER BY tp.UpVotes DESC, tp.CommentCount DESC;
