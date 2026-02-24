
WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(pb.PostId, 0) AS IsBountyPost,
        p.OwnerUserId  -- Added OwnerUserId to use in the main query
    FROM
        Posts p
    LEFT JOIN (
        SELECT DISTINCT p1.Id AS PostId
        FROM Posts p1
        JOIN Votes v1 ON p1.Id = v1.PostId
        WHERE v1.VoteTypeId = 8
    ) pb ON p.Id = pb.PostId
)
SELECT
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount,
    ua.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount AS PostAnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.IsBountyPost
FROM
    UserActivity ua
JOIN
    PostStats ps ON ua.UserId = ps.OwnerUserId
ORDER BY
    ua.PostCount DESC, ua.UpVotes DESC
LIMIT 100;
