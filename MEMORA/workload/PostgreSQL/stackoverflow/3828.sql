
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate) / 3600.0) ) AS AvgPostAgeInHours
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId
),
CloseReasonCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalViews,
    ue.AcceptedAnswers,
    ue.AvgPostAgeInHours,
    ps.Title,
    ps.CommentCount,
    ps.RankByScore,
    COALESCE(cr.CloseCount, 0) AS CloseCount,
    cr.LastCloseDate
FROM 
    UserEngagement ue
JOIN 
    PostStats ps ON ue.UserId = ps.AcceptedAnswerId
LEFT JOIN 
    CloseReasonCount cr ON ps.PostId = cr.PostId
WHERE 
    ue.TotalPosts > 0
ORDER BY 
    ue.TotalViews DESC, 
    ps.RankByScore ASC;
