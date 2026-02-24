
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COALESCE(SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        AVG(pl.LinkTypeId) AS AvgLinkType,
        COUNT(pl.RelatedPostId) AS TotalRelatedPosts
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        COALESCE(COUNT(h.Id), 0) AS ClosureCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId = 10
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.PositivePosts,
    ups.NegativePosts,
    ups.TotalViews,
    COALESCE(pls.AvgLinkType, 0) AS AverageLinkType,
    COALESCE(pls.TotalRelatedPosts, 0) AS RelatedPostsCount,
    cp.Title AS ClosedPostTitle,
    cp.ClosureCount
FROM 
    UserPostStats ups
LEFT JOIN 
    PostLinksSummary pls ON ups.TotalPosts > 0
LEFT JOIN 
    ClosedPosts cp ON cp.AcceptedAnswerId = ups.UserId
ORDER BY 
    ups.TotalViews DESC,
    ups.TotalPosts DESC
LIMIT 100 OFFSET 0;
