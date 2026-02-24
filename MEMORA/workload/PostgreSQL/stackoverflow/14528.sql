WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalUpvotedPosts,
    ups.AvgScore,
    ups.LastPostDate,
    ubs.TotalBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeStats ubs ON ups.UserId = ubs.UserId
ORDER BY 
    ups.TotalPosts DESC
LIMIT 100;