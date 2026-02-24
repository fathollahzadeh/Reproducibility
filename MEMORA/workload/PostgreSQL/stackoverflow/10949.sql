WITH PostMetrics AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(p.Id) FILTER (WHERE p.Score > 0) AS PositiveScorePosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        p.PostTypeId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(c.Score) AS TotalCommentScore,
        SUM(v.BountyAmount) AS TotalBountyReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    pmt.PostTypeId,
    pmt.TotalPosts,
    pmt.PositiveScorePosts,
    pmt.TotalViews,
    pmt.TotalAnswers,
    pmt.AverageScore,
    ueng.UserId,
    ueng.PostsCreated,
    ueng.TotalCommentScore,
    ueng.TotalBountyReceived
FROM 
    PostMetrics pmt
JOIN 
    UserEngagement ueng ON ueng.PostsCreated > 0
ORDER BY 
    pmt.PostTypeId, ueng.PostsCreated DESC;