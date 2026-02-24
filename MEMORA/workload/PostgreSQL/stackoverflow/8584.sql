WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        r.UserId,
        r.DisplayName,
        r.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalViews,
        ps.AverageScore
    FROM 
        RankedUsers r
    JOIN 
        PostStatistics ps ON r.UserId = ps.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.AverageScore,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ups.UserId) AS TotalBadges,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = ups.UserId) AS TotalComments
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC,
    ups.TotalPosts DESC
LIMIT 10;
