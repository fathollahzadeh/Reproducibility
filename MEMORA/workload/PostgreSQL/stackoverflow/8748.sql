
WITH UserReputation AS (
    SELECT
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        AboutMe,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes
    FROM Users
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.PostTypeId, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostStatistics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ur.Reputation,
        ur.NetVotes
    FROM RecentPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    ORDER BY rp.CreationDate DESC
    LIMIT 50
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Reputation,
    ps.NetVotes
FROM PostStatistics ps
WHERE ps.Score > 0
ORDER BY ps.NetVotes DESC, ps.CreationDate DESC;
