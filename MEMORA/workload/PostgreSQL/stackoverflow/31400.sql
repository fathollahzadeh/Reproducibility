WITH RECURSIVE VotesCTE AS (
    SELECT PostId,
           COUNT(*) AS TotalVotes,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY COUNT(*) DESC) AS rn
    FROM Votes
    GROUP BY PostId
    HAVING COUNT(*) > 0
),
RecentPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.ViewCount,
           p.Score,
           COALESCE(STRING_AGG(DISTINCT t.TagName, ', '), 'No Tags') AS Tags,
           u.DisplayName AS Author
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate,
           ph.UserDisplayName,
           ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT rp.Id AS PostID,
       rp.Title,
       rp.CreationDate,
       rp.ViewCount,
       rp.Score,
       rp.Tags,
       rp.Author,
       COALESCE(vs.TotalVotes, 0) AS TotalVotes,
       COALESCE(vs.UpVotes, 0) AS UpVotes,
       COALESCE(vs.DownVotes, 0) AS DownVotes,
       CASE WHEN cp.PostId IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
       cp.CloseReason AS CloseReasonDetails
FROM RecentPosts rp
LEFT JOIN VotesCTE vs ON rp.Id = vs.PostId
LEFT JOIN ClosedPosts cp ON rp.Id = cp.PostId
WHERE rp.ViewCount >= 100
ORDER BY rp.CreationDate DESC
LIMIT 50;