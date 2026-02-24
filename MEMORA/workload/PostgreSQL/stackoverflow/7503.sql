WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(v.VoteCount, 0) DESC, COALESCE(c.CommentCount, 0) DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
),
TopPosts AS (
    SELECT PostId, Title, CreationDate, VoteCount, CommentCount
    FROM RankedPosts
    WHERE Rank <= 10
)
SELECT
    tp.Title,
    tp.CreationDate,
    tp.VoteCount,
    tp.CommentCount,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    COALESCE(b.BadgeCount, 0) AS OwnerBadgeCount
FROM
    TopPosts tp
LEFT JOIN Users u ON tp.PostId = u.Id
LEFT JOIN (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
) b ON u.Id = b.UserId
ORDER BY tp.VoteCount DESC, tp.CommentCount DESC;
