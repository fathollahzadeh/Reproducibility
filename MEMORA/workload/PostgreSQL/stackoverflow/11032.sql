WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS TotalEditedPosts,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS TitleEdits,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenEdits
    FROM PostHistory ph
    GROUP BY ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalTagWikis,
        ups.TotalScore,
        ups.LastPostDate,
        phs.TotalEdits,
        phs.TotalEditedPosts,
        phs.TitleEdits,
        phs.CloseReopenEdits
    FROM UserPostStats ups
    LEFT JOIN PostHistoryStats phs ON ups.UserId = phs.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalTagWikis,
    TotalScore,
    LastPostDate,
    COALESCE(TotalEdits, 0) AS TotalEdits,
    COALESCE(TotalEditedPosts, 0) AS TotalEditedPosts,
    COALESCE(TitleEdits, 0) AS TitleEdits,
    COALESCE(CloseReopenEdits, 0) AS CloseReopenEdits
FROM CombinedStats
ORDER BY TotalScore DESC, TotalPosts DESC;