WITH PostSummary AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalWikis, 0) AS TotalWikis,
        COALESCE(ps.AverageScore, 0) AS AverageScore,
        COALESCE(ps.AverageViewCount, 0) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        PostSummary ps ON u.Id = ps.OwnerUserId
)

SELECT 
    u.UserId,
    u.Reputation,
    u.CreationDate,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalWikis,
    u.AverageScore,
    u.AverageViewCount
FROM 
    UserSummary u
ORDER BY 
    u.Reputation DESC;