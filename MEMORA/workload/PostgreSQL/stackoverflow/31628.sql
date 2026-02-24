
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
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
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
AggregatePostHistory AS (
    SELECT 
        PostId,
        SUM(CASE WHEN PostHistoryTypeId = 10 THEN ChangeCount ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN PostHistoryTypeId = 11 THEN ChangeCount ELSE 0 END) AS ReopenCount,
        SUM(CASE WHEN PostHistoryTypeId = 12 THEN ChangeCount ELSE 0 END) AS DeleteCount
    FROM 
        PostHistoryStats
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.ClosedDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(aph.CloseCount, 0) AS TotalCloseCount,
    COALESCE(aph.ReopenCount, 0) AS TotalReopenCount,
    COALESCE(aph.DeleteCount, 0) AS TotalDeleteCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    AggregatePostHistory aph ON rp.PostId = aph.PostId
WHERE 
    rp.OwnerRank = 1 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
