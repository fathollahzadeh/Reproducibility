
WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.Score) AS MedianScore,
        MAX(p.ViewCount) AS MaxViews,
        MIN(p.ViewCount) AS MinViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPostReasons AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalClosed,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.UserId
),
AggregatedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositivePosts, 0) AS PositivePosts,
        COALESCE(ps.MedianScore, 0) AS MedianScore,
        COALESCE(ps.MaxViews, 0) AS MaxViews,
        COALESCE(ps.MinViews, 0) AS MinViews,
        COALESCE(cb.TotalClosed, 0) AS TotalClosed,
        COALESCE(cb.CloseReasons, 'No reasons') AS CloseReasons,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        UserBadgeStats ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
    LEFT JOIN 
        ClosedPostReasons cb ON ub.UserId = cb.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    PositivePosts,
    MedianScore,
    MaxViews,
    MinViews,
    TotalClosed,
    CloseReasons,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CONCAT('Total Posts: ', TotalPosts, 
           '; Positive Posts: ', PositivePosts, 
           '; Median Score: ', MedianScore) AS SummaryStats
FROM 
    AggregatedStats
WHERE 
    (GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    TotalPosts DESC, PositivePosts DESC;
