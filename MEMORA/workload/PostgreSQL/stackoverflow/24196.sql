WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
           SUM(COALESCE(v.VoteCount, 0)) OVER (PARTITION BY p.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN (SELECT PostId, COUNT(*) AS VoteCount 
               FROM Votes 
               GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND p.ViewCount > 100
), 
ClosedPostDetails AS (
    SELECT ph.PostId,
           ph.Comment,
           ph.CreationDate AS CloseDate,
           p.Title AS ClosedPostTitle,
           ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
), 
FinalData AS (
    SELECT rp.PostId,
           rp.Title,
           rp.CreationDate,
           rp.CommentCount,
           rp.TotalVotes,
           COALESCE(cp.CloseRank, 0) AS CloseRank,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM RankedPosts rp
    LEFT JOIN ClosedPostDetails cp ON rp.PostId = cp.PostId
    LEFT JOIN Posts p ON rp.PostId = p.Id 
    LEFT JOIN Tags t ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.TotalVotes, cp.CloseRank
)
SELECT fd.*, 
       CASE 
           WHEN CloseRank > 0 THEN 'Closed'
           WHEN CommentCount = 0 AND TotalVotes = 0 THEN 'Orphan' 
           ELSE 'Active' 
       END AS PostStatus
FROM FinalData fd
WHERE fd.CommentCount > 0 
ORDER BY TotalVotes DESC, CreationDate ASC
LIMIT 100;