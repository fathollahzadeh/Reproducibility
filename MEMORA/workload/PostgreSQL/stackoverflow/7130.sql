WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
PostStats AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CommentCount,
        pa.CloseCount,
        pa.ReopenCount,
        pa.LastActivity,
        COALESCE(uvs.Upvotes, 0) AS TotalUpvotes,
        COALESCE(uvs.Downvotes, 0) AS TotalDownvotes,
        (COALESCE(uvs.Upvotes, 0) - COALESCE(uvs.Downvotes, 0)) AS NetVotes
    FROM PostActivity pa
    LEFT JOIN UserVoteStats uvs ON pa.PostId = uvs.UserId
)
SELECT 
    ps.Title,
    ps.CommentCount,
    ps.CloseCount,
    ps.ReopenCount,
    ps.LastActivity,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.NetVotes
FROM PostStats ps
ORDER BY ps.NetVotes DESC, ps.LastActivity DESC
LIMIT 10;