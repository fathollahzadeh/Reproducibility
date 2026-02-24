WITH PostStats AS (
    SELECT
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.CommentCount) AS AvgCommentCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.FavoriteCount) AS AvgFavoriteCount
    FROM
        Posts p
    GROUP BY
        p.PostTypeId
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
)

SELECT
    pts.PostTypeId,
    pts.TotalPosts,
    pts.AcceptedAnswers,
    pts.TotalScore,
    pts.AvgViewCount,
    pts.AvgCommentCount,
    pts.AvgAnswerCount,
    pts.AvgFavoriteCount,
    ua.UserId,
    ua.PostsCreated,
    ua.BadgesEarned,
    ua.TotalBounties
FROM
    PostStats pts
JOIN UserActivity ua ON ua.PostsCreated > 0
ORDER BY
    pts.TotalPosts DESC, ua.PostsCreated DESC;