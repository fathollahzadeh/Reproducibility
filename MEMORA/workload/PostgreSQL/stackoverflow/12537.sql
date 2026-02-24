
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        AVG(EXTRACT(EPOCH FROM (COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP) - p.CreationDate))) AS AvgTimeToActivity
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.NegativeScorePosts,
    ps.TotalViews,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.AvgTimeToActivity
FROM 
    PostTypes pt
JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;
