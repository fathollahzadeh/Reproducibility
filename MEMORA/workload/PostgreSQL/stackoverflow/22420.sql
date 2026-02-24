WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges ub
    GROUP BY 
        ub.UserId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate))) AS AverageResponseTime
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.Title,
    rp.Score,
    COALESCE(pa.CommentCount, 0) AS CommentCount,
    COALESCE(pa.CloseCount, 0) AS CloseCount,
    COALESCE(pa.ReopenCount, 0) AS ReopenCount,
    COALESCE(pa.AverageResponseTime, 999999) AS AverageResponseTime 
FROM 
    Users up
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.Rank = 1 
LEFT JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 50;