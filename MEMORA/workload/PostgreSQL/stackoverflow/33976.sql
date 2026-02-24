
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
CloseReasonDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    vb.BadgeCount AS TotalBadges,
    vb.GoldBadges,
    vb.SilverBadges,
    vb.BronzeBadges,
    COALESCE(crd.Reasons, 'No reasons provided') AS CloseReasons,
    rp.Rank,
    p.Score,
    p.ViewCount
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges vb ON u.Id = vb.UserId
LEFT JOIN 
    CloseReasonDetails crd ON p.Id = crd.PostId
WHERE 
    p.Score > 10
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 10 OFFSET 10;
