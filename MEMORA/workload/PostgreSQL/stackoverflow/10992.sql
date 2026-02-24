
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) AS AvgPostAge
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS TotalHistoryEntries,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    phs.TotalHistoryEntries,
    phs.LastEdited
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryStats phs ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = phs.PostId FETCH FIRST 1 ROW ONLY)
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC;
