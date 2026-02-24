
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > (
            SELECT AVG(Score) 
            FROM Posts 
            WHERE OwnerUserId = p.OwnerUserId
        )
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
ClosePostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    pb.BadgeCount,
    pb.GoldBadges,
    pb.SilverBadges,
    pb.BronzeBadges,
    ch.CloseCount,
    ch.LastClosedDate
FROM 
    RankedPosts p
JOIN 
    UserBadges pb ON p.OwnerUserId = pb.UserId
LEFT JOIN 
    ClosePostHistory ch ON p.PostId = ch.PostId
WHERE 
    (pb.BadgeCount > 5 OR ch.CloseCount > 2)
    AND (p.ViewCount > 100 OR ch.LastClosedDate IS NULL)
    AND (p.Score BETWEEN 5 AND 100)
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 50
OFFSET 0;
