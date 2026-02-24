
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year')
), UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), RecentPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedPostsCount
    FROM 
        PostLinks pl
    WHERE 
        pl.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '6 months')
    GROUP BY 
        pl.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    us.TotalViews,
    us.TotalComments,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate,
    COALESCE(rp.PostRank, 0) AS UserPostRank,
    COALESCE(rpl.RelatedPostsCount, 0) AS RelatedPostsCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    RecentPostLinks rpl ON rp.PostId = rpl.PostId
WHERE 
    (us.TotalPosts > 0 OR us.GoldBadges > 0)
ORDER BY 
    us.TotalViews DESC, 
    us.TotalPosts DESC;
