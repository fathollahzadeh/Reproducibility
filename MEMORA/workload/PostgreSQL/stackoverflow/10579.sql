
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.PostTypeId) AS UniquePostTypes,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Id, pt.Name
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.UniquePostTypes,
    ups.TotalViews,
    ups.TotalScore,
    ups.AvgViewsPerPost,
    ups.AvgScorePerPost,
    pts.PostTypeName,
    pts.TotalPosts AS PostTypeTotalPosts,
    pts.TotalViews AS PostTypeTotalViews,
    pts.AvgScore AS PostTypeAvgScore
FROM 
    UserPostStats ups
CROSS JOIN 
    PostTypeStats pts
ORDER BY 
    ups.TotalPosts DESC, pts.TotalViews DESC;
