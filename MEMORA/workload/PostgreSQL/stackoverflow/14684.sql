
WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT l.Id) AS RelatedLinks,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastEditDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        PostLinks l ON p.Id = l.PostId
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.Upvotes,
    us.Downvotes,
    us.BadgesCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.RelatedLinks,
    ps.LastEditDate
FROM
    UserStatistics us
JOIN
    PostStatistics ps ON us.UserId = ps.PostId
ORDER BY
    us.TotalPosts DESC, ps.Score DESC, ps.ViewCount DESC;
