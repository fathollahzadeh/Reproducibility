
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CloseReasonDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
UserPosts AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.TotalPosts,
    up.NegativePosts,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    UserPosts up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON rp.Rank = 1 AND rp.PostId IN (SELECT PostId FROM CloseReasonDetails)
LEFT JOIN 
    CloseReasonDetails cr ON rp.PostId = cr.PostId
WHERE 
    up.TotalPosts > 0
ORDER BY 
    up.TotalPosts DESC, ub.BadgeCount DESC;
