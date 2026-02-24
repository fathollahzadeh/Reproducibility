WITH PostStats AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS TotalPosts, 
        AVG(p.Score) AS AvgScore, 
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.FavoriteCount) AS TotalFavorites
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostType, 
    ps.TotalPosts, 
    ps.AvgScore, 
    ps.TotalViews, 
    ps.TotalAnswers, 
    ps.TotalFavorites,
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalBounties
FROM 
    PostStats ps
LEFT JOIN 
    UserStats us ON us.UserId IS NOT NULL
ORDER BY 
    ps.TotalPosts DESC, us.TotalBadges DESC;