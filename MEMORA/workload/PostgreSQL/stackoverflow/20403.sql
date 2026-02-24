
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.OwnerUserId
),
UsersWithInteractions AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositivePosts, 0) AS PositivePosts,
        COALESCE(ps.NegativePosts, 0) AS NegativePosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.PositivePosts,
    u.NegativePosts,
    u.TotalViews,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(ROUND((CAST(u.PositivePosts AS FLOAT) / NULLIF(u.TotalPosts, 0)) * 100, 2), 0) AS PositivePostPercentage,
    CASE 
        WHEN u.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN u.ReputationRank BETWEEN 11 AND 50 THEN 'Active User'
        ELSE 'New Member'
    END AS UserCategory,
    CASE 
        WHEN u.PositivePosts > 10 THEN 'Active Participant'
        WHEN u.NegativePosts > 5 THEN 'Needs Improvement'
        ELSE 'Balanced'
    END AS EngagementLevel
FROM 
    UsersWithInteractions u
ORDER BY 
    u.Reputation DESC, 
    u.GoldBadges DESC, 
    u.TotalPosts DESC;
