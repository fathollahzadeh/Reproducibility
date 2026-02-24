WITH UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        pb.TotalPosts,
        pb.TotalComments,
        pb.TotalViews,
        pb.AvgScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeList, 'No Badges') AS BadgeList
    FROM 
        Users u
    LEFT JOIN 
        PostStats pb ON u.Id = pb.OwnerUserId
    LEFT JOIN 
        UsersWithBadges ub ON u.Id = ub.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalComments,
    up.TotalViews,
    up.AvgScore,
    up.BadgeCount,
    up.BadgeList 
FROM 
    UserPerformance up
WHERE 
    (up.TotalPosts > 10 OR up.BadgeCount > 0)
ORDER BY 
    up.TotalViews DESC, 
    up.AvgScore DESC
LIMIT 20;
