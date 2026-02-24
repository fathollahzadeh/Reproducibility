WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Name
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AverageScore AS UserAverageScore,
    ups.TotalViews,
    bc.TotalBadges,
    ptc.PostType,
    ptc.PostCount,
    ptc.AverageScore AS PostTypeAverageScore
FROM 
    UserPostStats ups
JOIN 
    BadgeCounts bc ON ups.UserId = bc.UserId
JOIN 
    PostTypeCounts ptc ON ptc.PostCount > 0
ORDER BY 
    ups.TotalPosts DESC,
    ptc.PostCount DESC;