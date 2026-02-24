WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS TotalOwners,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalOwners,
    ps.TotalViews,
    ps.TotalScore,
    ps.AvgScore,
    ps.AvgViews,
    ps.LatestPostDate
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
ORDER BY 
    ps.TotalPosts DESC;