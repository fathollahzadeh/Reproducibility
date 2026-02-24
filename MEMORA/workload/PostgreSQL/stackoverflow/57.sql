
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    um.UserId,
    um.DisplayName,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    um.TotalViews,
    cp.Title AS ClosedPostTitle,
    cp.CreationDate AS ClosedPostDate,
    cp.UserDisplayName AS ClosureUser,
    cp.Comment AS ClosureComment
FROM 
    UserMetrics um
LEFT JOIN 
    RankedPosts rp ON um.UserId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
WHERE 
    (um.GoldBadges > 0 OR um.SilverBadges > 0 OR um.BronzeBadges > 0)
    AND (rp.ViewCount IS NOT NULL OR cp.PostId IS NOT NULL)
ORDER BY 
    um.TotalViews DESC, 
    rp.Score DESC NULLS LAST;
