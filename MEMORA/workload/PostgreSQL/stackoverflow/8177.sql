WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostMeta AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN UNNEST(string_to_array(p.Tags, '<>')) AS tag ON true
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.Score,
        pm.ViewCount,
        pm.Tags,
        ROW_NUMBER() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS Rank
    FROM PostMeta pm
    WHERE pm.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.AnswerCount,
    us.QuestionCount,
    us.CommentCount,
    us.BadgeCount,
    us.VoteCount,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.Tags AS TopPostTags
FROM UserStats us
LEFT JOIN TopPosts tp ON us.UserId = tp.PostId
WHERE tp.Rank <= 5
ORDER BY us.Reputation DESC, us.VoteCount DESC;