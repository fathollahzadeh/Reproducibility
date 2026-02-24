WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostsWithHistory AS (
    SELECT 
        p.*, 
        pha.HistoryCount, 
        pha.LastModified
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryAggregates pha ON p.Id = pha.PostId
)

SELECT 
    u.DisplayName,
    up.PostCount,
    up.TotalScore,
    up.TotalViews,
    up.AvgViewsPerPost,
    p.Title,
    p.HistoryCount,
    p.LastModified,
    p.CreationDate AS PostCreationDate
FROM 
    UserPosts up
JOIN 
    Users u ON up.UserId = u.Id
JOIN 
    PostsWithHistory p ON u.Id = p.OwnerUserId
ORDER BY 
    up.TotalScore DESC, 
    up.PostCount DESC;