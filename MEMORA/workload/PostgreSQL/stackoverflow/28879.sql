WITH TagCounts AS (
    SELECT
        TagName,
        COUNT(*) AS PostCount
    FROM Tags
    GROUP BY TagName
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS Author,
        p.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(l.LinkedScore, 0) AS LinkedScore
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN LinkTypeId = 1 THEN 1 ELSE 0 END) AS LinkedScore
        FROM PostLinks
        GROUP BY PostId
    ) l ON p.Id = l.PostId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) b ON u.Id = b.UserId
),
FilteredPosts AS (
    SELECT
        pd.*,
        tc.PostCount
    FROM PostDetails pd
    JOIN TagCounts tc ON pd.Title LIKE '%' || tc.TagName || '%'
)

SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.PostType,
    fp.Author,
    fp.AnswerCount,
    fp.CommentCount,
    fp.BadgeCount,
    fp.LinkedScore,
    fp.PostCount
FROM FilteredPosts fp
WHERE fp.PostCount > 10
ORDER BY fp.ViewCount DESC, fp.CreationDate DESC
LIMIT 100;
