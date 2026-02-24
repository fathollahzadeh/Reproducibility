WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments,
        SUM(p.FavoriteCount) AS TotalFavorites,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.AverageScore,
    ps.TotalViews,
    ps.TotalComments,
    ps.TotalFavorites,
    ps.LastPostDate
FROM 
    UserReputation u
LEFT JOIN 
    PostStats ps ON u.UserId = ps.OwnerUserId
ORDER BY 
    u.Reputation DESC;