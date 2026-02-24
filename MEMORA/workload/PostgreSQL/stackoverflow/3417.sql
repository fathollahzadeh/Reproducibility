WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.PostId) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldCount, 0) AS GoldBadges,
        COALESCE(ub.SilverCount, 0) AS SilverBadges,
        COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageViews, 0) AS AverageViews,
        COALESCE(cp.ClosedCount, 0) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON u.Id = cp.UserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalScore,
    AverageViews,
    ClosedPosts,
    CASE 
        WHEN TotalPosts > 10 AND ClosedPosts > 5 THEN 'Active Contributor'
        WHEN ClosedPosts = 0 THEN 'Non-Contributor'
        ELSE 'Moderate Contributor'
    END AS ContributorStatus
FROM 
    FinalStats
WHERE 
    (TotalPosts > 0 OR GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    TotalScore DESC, DisplayName;