
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    ua.UserId, 
    ua.DisplayName,
    ua.Upvotes - ua.Downvotes AS NetVotes,
    ua.CommentCount,
    ua.PostCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.TotalComments,
    ps.AverageScore,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    cp.LastClosedDate
FROM UserActivity ua
JOIN PostStats ps ON ua.UserId = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE ua.Upvotes > 0 
  AND (ua.PostCount > 5 OR ua.CommentCount > 10) 
ORDER BY NetVotes DESC, ua.DisplayName ASC;
