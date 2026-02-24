WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
TopPosts AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
),
VoteStatistics AS (
    SELECT p.Id AS PostId, COUNT(v.Id) AS TotalVotes,
           SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY p.Id
)
SELECT tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName,
       vs.TotalVotes, vs.UpVotes, vs.DownVotes,
       COALESCE(ph.Comment, 'No closure comment') AS ClosureComment,
       COALESCE(PR.Name, 'No close reason') AS CloseReason
FROM TopPosts tp
LEFT JOIN PostHistory ph ON tp.Id = ph.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN CloseReasonTypes PR ON CAST(ph.Comment AS INT) = PR.Id
LEFT JOIN VoteStatistics vs ON tp.Id = vs.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC;
