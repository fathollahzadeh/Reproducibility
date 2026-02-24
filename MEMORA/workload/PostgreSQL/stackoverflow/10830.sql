
WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.AnswerCount) AS AvgAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(CASE WHEN p.ViewCount > 0 THEN 1 END) AS PostsViewed,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.DisplayName, u.Id
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    pc.PositivePosts,
    pc.NegativePosts,
    pc.AvgViews,
    pc.AvgAnswers,
    ua.DisplayName,
    ua.PostsViewed,
    ua.TotalBounty
FROM 
    PostCounts pc
JOIN 
    UserActivity ua ON ua.PostsViewed > 0
ORDER BY 
    pc.TotalPosts DESC, 
    ua.TotalBounty DESC;
