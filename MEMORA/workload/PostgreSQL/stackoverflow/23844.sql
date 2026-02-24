
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
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

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INTEGER) = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)

SELECT 
    up.UserId,
    u.DisplayName,
    COALESCE(up.BadgeCount, 0) AS TotalBadges,
    COALESCE(up.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(up.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(up.BronzeBadges, 0) AS TotalBronzeBadges,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Score,
    DATE_PART('epoch', TIMESTAMP '2024-10-01 12:34:56' - rp.CreationDate) AS PostAgeInSeconds,
    cp.CloseReasons
FROM 
    UserBadges up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.BadgeCount IS NOT NULL 
    OR rp.PostId IS NOT NULL
ORDER BY 
    u.Reputation DESC, 
    TotalBadges DESC, 
    rp.Score DESC NULLS LAST;
