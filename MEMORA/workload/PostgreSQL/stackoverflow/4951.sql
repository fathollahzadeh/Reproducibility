
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, a.AcceptedAnswerId
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.AcceptedAnswerId,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpvoteCount DESC) AS UpvoteRank
    FROM PostStats ps
    WHERE ps.UpvoteCount > 0
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    pp.Title AS PopularPostTitle,
    pp.CommentCount AS PopularPostCommentCount,
    pp.UpvoteCount AS PopularPostUpvoteCount,
    pp.DownvoteCount AS PopularPostDownvoteCount
FROM UserActivity ua
LEFT JOIN PopularPosts pp ON ua.PostRank = pp.UpvoteRank
WHERE ua.PostCount > 5
ORDER BY ua.PostCount DESC, ua.UpvoteCount DESC;
