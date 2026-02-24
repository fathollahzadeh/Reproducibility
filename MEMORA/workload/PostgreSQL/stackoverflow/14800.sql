WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS TotalHistoryEntries,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.TotalViews,
    ups.TotalScore,
    ups.TotalBadges,
    phs.PostId,
    phs.Title,
    phs.TotalHistoryEntries,
    phs.LastEditDate
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryStats phs ON ups.UserId = phs.PostId
ORDER BY 
    ups.TotalPosts DESC, ups.TotalScore DESC;