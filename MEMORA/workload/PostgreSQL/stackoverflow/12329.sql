WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            ParentId,
            COUNT(*) AS AnswerCount
        FROM
            Posts
        WHERE
            PostTypeId = 2
        GROUP BY
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS VoteCount
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT
            UserId,
            COUNT(*) AS BadgeCount
        FROM
            Badges
        GROUP BY
            UserId
    ) b ON p.OwnerUserId = b.UserId
    WHERE
        p.PostTypeId = 1
)
SELECT
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    VoteCount,
    BadgeCount,
    (Score / NULLIF(ViewCount, 0)) AS ScorePerView,
    (AnswerCount / NULLIF(ViewCount, 0)) AS AnswersPerView,
    (CommentCount / NULLIF(ViewCount, 0)) AS CommentsPerView,
    (BadgeCount / NULLIF(ViewCount, 0)) AS BadgesPerView
FROM
    PostStats
ORDER BY
    ViewCount DESC
LIMIT 10;
