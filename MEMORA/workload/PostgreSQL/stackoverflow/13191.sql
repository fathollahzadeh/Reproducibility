WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikes,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
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
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.Wikes,
    ups.TotalScore,
    ups.TotalViews,
    COALESCE(phs.TotalEdits, 0) AS TotalEdits,
    COALESCE(phs.UniquePostsEdited, 0) AS UniquePostsEdited
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryStats phs ON ups.UserId = phs.UserId
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC;
