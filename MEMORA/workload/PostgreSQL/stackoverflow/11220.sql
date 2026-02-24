WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryCount AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalPostHistories
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
    ups.TotalViews,
    ups.TotalScore,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    COALESCE(phc.TotalPostHistories, 0) AS TotalPostHistories
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgeCount bc ON ups.UserId = bc.UserId
LEFT JOIN 
    PostHistoryCount phc ON ups.UserId = phc.UserId
ORDER BY 
    ups.TotalPosts DESC, 
    ups.TotalScore DESC
LIMIT 100;