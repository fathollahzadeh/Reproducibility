
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalScore,
        us.AvgViews,
        us.LastPostDate
    FROM 
        UserStatistics us
    WHERE 
        us.TotalPosts > 5 AND 
        us.TotalScore > 100
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.TotalScore,
    au.AvgViews,
    ra.TotalComments,
    ra.LastCommentDate,
    au.LastPostDate
FROM 
    ActiveUsers au
LEFT JOIN 
    RecentActivity ra ON au.UserId = ra.UserId
ORDER BY 
    au.TotalScore DESC, au.LastPostDate DESC;
