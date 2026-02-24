
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PostsHighViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, ph.PostHistoryTypeId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.PositiveScorePosts,
    ups.PostsHighViews,
    ups.AvgScore,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.HistoryCount ELSE 0 END) AS CloseVotes,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.HistoryCount ELSE 0 END) AS ReopenVotes,
    SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.HistoryCount ELSE 0 END) AS DeletionVotes,
    SUM(CASE WHEN ph.PostHistoryTypeId = 13 THEN ph.HistoryCount ELSE 0 END) AS UndeletionVotes
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistories ph ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
GROUP BY 
    ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers, ups.PositiveScorePosts, ups.PostsHighViews, ups.AvgScore
ORDER BY 
    ups.TotalPosts DESC;
