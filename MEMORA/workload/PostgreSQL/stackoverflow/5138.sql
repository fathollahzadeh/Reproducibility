
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        p.Title,
        p.Score,
        pa.CommentCount,
        pa.VoteCount,
        pa.CloseCount,
        pa.ReopenCount,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        p.OwnerUserId
    FROM Posts p
    JOIN PostActivity pa ON p.Id = pa.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    pd.*,
    uvc.TotalVotes,
    uvc.UpVotes,
    uvc.DownVotes
FROM PostDetails pd
JOIN UserVoteCounts uvc ON pd.OwnerUserId = uvc.UserId
WHERE pd.Score > 10
ORDER BY pd.Score DESC, pd.CommentCount DESC, uvc.TotalVotes DESC
LIMIT 100;
