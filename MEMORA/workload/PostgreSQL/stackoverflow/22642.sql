
WITH UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAggregates AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS HistoryCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.PostId END) AS ClosureChanges
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    GROUP BY 
        ph.UserId
),
EngagementMetrics AS (
    SELECT 
        ui.UserId,
        ui.DisplayName,
        ui.TotalPosts,
        ui.PositivePosts,
        ui.NegativePosts,
        ui.TotalComments,
        ph.HistoryCount,
        ph.AcceptedAnswers,
        ph.ClosureChanges,
        (COALESCE(ui.TotalPosts, 0) + COALESCE(ui.TotalComments, 0) + COALESCE(ph.HistoryCount, 0)) AS EngagementScore
    FROM 
        UserInteractions ui
    LEFT JOIN 
        PostHistoryAggregates ph ON ui.UserId = ph.UserId
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY EngagementScore DESC) AS UserRank
    FROM 
        EngagementMetrics
)

SELECT 
    ru.DisplayName,
    ru.TotalPosts,
    ru.PositivePosts,
    ru.NegativePosts,
    ru.TotalComments,
    ru.HistoryCount,
    ru.AcceptedAnswers,
    ru.ClosureChanges,
    CASE 
        WHEN ru.UserRank <= 10 THEN 'Top Contributor'
        WHEN ru.UserRank BETWEEN 11 AND 50 THEN 'Contributor'
        ELSE 'Occasional User'
    END AS UserCategory
FROM 
    RankedUsers ru
WHERE 
    ru.AcceptedAnswers > 0 
OR 
    ru.ClosureChanges > 0
ORDER BY 
    ru.UserRank;
