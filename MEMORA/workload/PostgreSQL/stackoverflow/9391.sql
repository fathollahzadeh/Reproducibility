
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount
FROM UserActivity ua
JOIN Users u ON ua.UserId = u.Id
JOIN PostStats ps ON ps.ViewCount > 50
ORDER BY ua.TotalPosts DESC, ps.Score DESC
LIMIT 50;
