WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(score), 0) AS AverageScore,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(AVG(score), 0) DESC) AS UserPostRank
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ubc.TotalBadges,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedCount,
    CASE 
        WHEN ps.UserPostRank = 1 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON u.Id = cp.UserId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (ubc.TotalBadges > 5 OR ps.TotalPosts > 10)
    AND COALESCE(ps.AverageScore, 0) > 0
ORDER BY 
    u.Reputation DESC, 
    ubc.TotalBadges DESC;
