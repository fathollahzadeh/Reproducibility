
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.PositivePosts,
    ua.NegativePosts,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate
FROM UserActivity ua
LEFT JOIN PostStats ps ON ua.UserId = ps.PostId AND ps.PostRank = 1
WHERE ua.Reputation > 1000
  AND (ua.PostCount > 5 OR ps.AnswerCount > 2 OR ps.CommentCount > 10)
  AND ps.CreationDate IS NOT NULL
ORDER BY ua.Reputation DESC, ps.ViewCount DESC
LIMIT 10;
