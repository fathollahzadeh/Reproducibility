
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

PostEngagement AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(pt.Name, 'Unknown') AS PostType
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
)

SELECT
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.LastPostDate,
    pe.PostId,
    pe.Title,
    pe.PostType,
    pe.Score,
    pe.ViewCount,
    pe.AnswerCount,
    pe.CommentCount
FROM UserStats us
JOIN PostEngagement pe ON us.UserId = pe.OwnerUserId
ORDER BY us.TotalPosts DESC, pe.Score DESC
FETCH FIRST 100 ROWS ONLY;
