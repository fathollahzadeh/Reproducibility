
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
FlaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    u.DisplayName AS UserName,
    p.Title,
    p.CommentCount,
    COALESCE(uvs.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvs.DownVotes, 0) AS UserDownVotes,
    fp.CloseReason,
    fp.CreationDate AS CloseDate,
    p.PostRank
FROM PostSummary p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserVoteSummary uvs ON u.Id = uvs.UserId
LEFT JOIN FlaggedPosts fp ON p.PostId = fp.PostId
WHERE p.CommentCount > 5 
  AND (p.UpVotes - p.DownVotes) > 0
ORDER BY p.PostRank, p.Title 
LIMIT 10;
