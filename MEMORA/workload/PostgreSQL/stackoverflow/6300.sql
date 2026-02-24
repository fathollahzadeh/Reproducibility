WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.TotalViews,
        COALESCE(phs.TotalEdits, 0) AS TotalEdits,
        COALESCE(phs.UniquePostsEdited, 0) AS UniquePostsEdited
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryStats phs ON ups.UserId = phs.UserId
)
SELECT 
    cs.DisplayName,
    cs.TotalPosts,
    cs.TotalQuestions,
    cs.TotalAnswers,
    cs.TotalScore,
    cs.TotalViews,
    cs.TotalEdits,
    cs.UniquePostsEdited
FROM 
    CombinedStats cs
WHERE 
    cs.TotalPosts > 0
ORDER BY 
    cs.TotalScore DESC,
    cs.TotalPosts DESC
LIMIT 10;
