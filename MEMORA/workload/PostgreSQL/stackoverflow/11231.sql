
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.AverageReputation,
        ps.TotalPosts AS UserTotalPosts,
        ps.TotalAcceptedAnswers,
        ps.AverageViews,
        ps.AverageScore
    FROM 
        UserStatistics us
    LEFT JOIN 
        PostStatistics ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AverageReputation,
    COALESCE(ups.UserTotalPosts, 0) AS UserTotalPosts,
    COALESCE(ups.TotalAcceptedAnswers, 0) AS TotalAcceptedAnswers,
    COALESCE(ups.AverageViews, 0) AS AverageViews,
    COALESCE(ups.AverageScore, 0) AS AverageScore
FROM 
    UserPostStats ups
ORDER BY 
    ups.AverageReputation DESC, 
    ups.TotalPosts DESC;
