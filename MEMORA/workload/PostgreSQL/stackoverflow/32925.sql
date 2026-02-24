
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS NewlyClosedPosts,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenedPostsCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    COALESCE(cps.ClosedPostCount, 0) AS TotalClosedPosts,
    COALESCE(cps.NewlyClosedPosts, 0) AS NewlyClosedPosts,
    COALESCE(cps.ReopenedPostsCount, 0) AS ReopenedPostsCount,
    (CAST(ua.TotalAnswers AS FLOAT) / NULLIF(ua.TotalQuestions, 0)) * 100 AS AnswerToQuestionRatio,
    (ua.TotalClosedPosts - ua.TotalReopenedPosts) AS NetClosedPosts
FROM 
    UserActivity ua
LEFT JOIN 
    ClosedPostStats cps ON ua.UserId = cps.UserId
ORDER BY 
    ua.TotalPosts DESC
LIMIT 100;
