WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY pt.Name
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ROUND(ps.TotalScore * 1.0 / NULLIF(ps.TotalPosts, 0), 2) AS AvgScorePerPost,
    ROUND(ps.TotalViews * 1.0 / NULLIF(ps.TotalPosts, 0), 2) AS AvgViewsPerPost
FROM PostStats ps
ORDER BY ps.TotalPosts DESC;