WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
ClosedPostCounts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.PostId) AS ClosedPosts
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
    GROUP BY 
        ph.UserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(pa.TotalPosts, 0) AS TotalPosts,
        COALESCE(pa.TotalScore, 0) AS TotalScore,
        COALESCE(pa.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(cpc.ClosedPosts, 0) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostAggregates pa ON u.Id = pa.OwnerUserId
    LEFT JOIN 
        ClosedPostCounts cpc ON u.Id = cpc.UserId
),
RankedUsers AS (
    SELECT 
        up.*,
        RANK() OVER (ORDER BY up.TotalScore DESC, up.TotalPosts DESC) AS PerformanceRank
    FROM 
        UserPerformance up
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.TotalPosts,
    ru.TotalScore,
    ru.AvgViewCount,
    ru.ClosedPosts,
    ru.PerformanceRank
FROM 
    RankedUsers ru
WHERE 
    ru.PerformanceRank <= 10
ORDER BY 
    ru.PerformanceRank;