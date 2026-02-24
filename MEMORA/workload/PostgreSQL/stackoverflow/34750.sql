WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
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
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteRestoreCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pp.CreationDate,
    pp.Score
FROM 
    RankedPosts pp
LEFT JOIN 
    PostHistoryAggregated ph ON pp.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON pp.OwnerUserId = ub.UserId
WHERE 
    (ub.BadgeCount > 5 OR pp.Score > 10) 
    AND pp.PostRank = 1
ORDER BY 
    pp.CreationDate DESC;