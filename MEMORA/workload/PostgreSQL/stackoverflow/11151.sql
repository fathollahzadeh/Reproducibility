
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        MIN(p.CreationDate) AS EarliestPostDate,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.PostTypeId,
    p.PostCount,
    p.TotalScore,
    p.TotalViews,
    p.AvgScore,
    p.AvgViews,
    p.EarliestPostDate,
    p.LatestPostDate,
    u.UserId,
    u.PostsCreated,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    PostStats p
LEFT JOIN 
    UserStats u ON u.PostsCreated > 0
ORDER BY 
    p.PostTypeId, u.PostsCreated DESC;
