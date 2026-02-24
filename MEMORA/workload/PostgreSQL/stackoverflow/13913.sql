WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10) THEN 1 ELSE 0 END) AS PostClosedCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (11) THEN 1 ELSE 0 END) AS PostReopenedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalTagWikis,
    ups.TotalViews,
    ups.AvgScore,
    phs.TotalEdits,
    phs.TitleEdits,
    phs.PostClosedCount,
    phs.PostReopenedCount
FROM 
    Users u
LEFT JOIN 
    UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN 
    PostHistoryStats phs ON u.Id = phs.UserId
ORDER BY 
    u.Reputation DESC;