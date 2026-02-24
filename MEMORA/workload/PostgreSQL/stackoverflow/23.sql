
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId, 
        ph.Comment AS CloseReason,
        ph.CreationDate
    FROM PostHistory ph 
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    u.DisplayName,
    pus.PostId,
    pus.Title,
    pus.CreationDate AS PostCreationDate,
    COALESCE(cpr.CloseReason, 'Open') AS PostCloseReason,
    uv.TotalVotes,
    uv.UpVotes,
    uv.DownVotes,
    uv.VoteRank
FROM Users u
JOIN RecentPosts pus ON u.Id = pus.OwnerUserId
LEFT JOIN ClosedPostReasons cpr ON pus.PostId = cpr.PostId
JOIN UserVoteStats uv ON u.Id = uv.UserId
WHERE uv.TotalVotes > 0
ORDER BY uv.VoteRank, pus.CreationDate DESC;
