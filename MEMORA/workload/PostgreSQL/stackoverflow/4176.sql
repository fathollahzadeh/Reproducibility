
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    rp.PostId,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews,
    cp.IsClosed
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.RN = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (us.TotalPosts > 10 OR us.GoldBadges > 0)
ORDER BY 
    us.DisplayName, LatestPostDate DESC
LIMIT 50;
