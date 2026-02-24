WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        COUNT(c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pv.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes pv ON p.Id = pv.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.UpVotes,
        ua.DownVotes,
        ua.BadgeCount,
        ua.CommentCount,
        RANK() OVER (ORDER BY ua.UpVotes DESC, ua.PostCount DESC) AS Rank
    FROM UserActivity ua
    WHERE ua.PostCount > 0
)
SELECT 
    u.DisplayName AS UserName,
    u.PostCount,
    u.UpVotes,
    u.DownVotes,
    u.BadgeCount,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreatedDate,
    ps.ViewCount AS PostViewCount,
    ps.Score AS PostScore,
    ps.CommentCount AS PostCommentCount,
    ps.VoteCount AS PostVoteCount
FROM TopUsers u
JOIN PostStatistics ps ON u.PostCount > 3
WHERE u.Rank <= 10
ORDER BY u.UpVotes DESC, u.PostCount DESC, ps.ViewCount DESC;