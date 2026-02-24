
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
LatestPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INTEGER) = ct.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    lb.PostId AS LatestPostId,
    lb.Title AS LatestPostTitle,
    lb.CreationDate AS LatestPostDate,
    lb.Score AS LatestPostScore,
    cb.CloseReasons AS ClosedPostReasons,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedUsers ru
LEFT JOIN 
    LatestPosts lb ON ru.UserId = lb.OwnerUserId AND lb.PostRank = 1
LEFT JOIN 
    ClosedPosts cb ON lb.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
WHERE 
    ru.ReputationRank <= 100 
    AND (cb.CloseReasons IS NULL OR cb.CloseReasons NOT LIKE '%Duplicate%')
ORDER BY 
    ru.Reputation DESC,
    lb.Score DESC
LIMIT 50;
