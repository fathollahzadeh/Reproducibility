WITH PostMetrics AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(CASE WHEN p.CommentCount > 0 THEN 1 ELSE 0 END) AS PostsWithComments,
        SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS PostsWithFavorites
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pt.Name
)
SELECT
    PostType,
    TotalPosts,
    TotalScore,
    AverageViewCount,
    TotalAcceptedAnswers,
    PostsWithComments,
    PostsWithFavorites
FROM
    PostMetrics
ORDER BY
    TotalPosts DESC;