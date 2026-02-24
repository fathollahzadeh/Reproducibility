
WITH UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    uwb.UserId,
    uwb.DisplayName,
    uwb.GoldBadges,
    uwb.SilverBadges,
    uwb.BronzeBadges,
    ps.TotalPosts AS UserTotalPosts,
    ps.TotalScore,
    ps.AvgViewCount,
    COALESCE(cpr.ClosedReasons, 'No close reasons') AS ClosedReasons
FROM 
    UserWithBadges uwb
LEFT JOIN 
    PostStats ps ON uwb.UserId = ps.OwnerUserId
LEFT JOIN 
    ClosedPostReasons cpr ON ps.OwnerUserId = cpr.PostId
WHERE 
    uwb.TotalPosts > 5 
    AND (uwb.GoldBadges > 0 OR uwb.SilverBadges > 0)
ORDER BY 
    uwb.GoldBadges DESC, uwb.SilverBadges DESC, uwb.BronzeBadges DESC;
