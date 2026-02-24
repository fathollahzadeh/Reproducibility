WITH PostStats AS (
    SELECT
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalPositiveScores,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS TotalNegativeScores,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(COALESCE(a.AnswerCount, 0)) AS AvgAnswerCount,
        AVG(COALESCE(c.CommentCount, 0)) AS AvgCommentCount
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
    GROUP BY
        p.PostTypeId
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.Views) AS TotalViews,
        AVG(u.Reputation) AS AvgReputation
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)

SELECT
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalPositiveScores,
    ps.TotalNegativeScores,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    us.TotalBadges,
    us.TotalViews,
    us.AvgReputation
FROM
    PostStats ps
JOIN PostTypes pt ON ps.PostTypeId = pt.Id
JOIN UserStats us ON us.UserId = (SELECT MIN(Id) FROM Users) 
ORDER BY
    ps.TotalPosts DESC;