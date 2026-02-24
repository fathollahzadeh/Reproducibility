
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CommentCount) AS AvgCommentsPerPost,
        AVG(p.FavoriteCount) AS AvgFavoritesPerPost,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.DisplayName, u.Reputation
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.UniqueUsers,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgCommentsPerPost,
    ps.AvgFavoritesPerPost,
    ps.LatestPostDate,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalBadgeClass,
    us.VoteCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.BadgeCount > 0
ORDER BY 
    ps.TotalPosts DESC, us.Reputation DESC;
