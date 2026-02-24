WITH PostSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalUserPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserSummary AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        SUM(CASE WHEN Reputation >= 1000 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM 
        Users
),

BadgeSummary AS (
    SELECT 
        COUNT(*) AS TotalBadges,
        COUNT(DISTINCT UserId) AS UsersWithBadges,
        MAX(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        MAX(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        MAX(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    ps.TotalUserPosts,
    us.TotalUsers,
    us.AverageReputation,
    us.ActiveUsers,
    bs.TotalBadges,
    bs.UsersWithBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges
FROM 
    PostSummary ps,
    UserSummary us,
    BadgeSummary bs
ORDER BY 
    ps.TotalPosts DESC;