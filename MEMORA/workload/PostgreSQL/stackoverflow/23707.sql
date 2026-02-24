WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            WHEN u.Reputation > 1000 THEN 'Expert'
            ELSE 'Undefined'
        END AS ReputationLevel
    FROM 
        Users u
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (50, 52, 53) THEN 1 END) AS BumpCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
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
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ur.ReputationLevel,
    COALESCE(pus.CloseOpenCount, 0) AS CloseOpenCount,
    COALESCE(pus.DeleteCount, 0) AS DeleteCount,
    COALESCE(pus.BumpCount, 0) AS BumpCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserReputation ur ON ur.UserId = up.Id
LEFT JOIN 
    PostHistorySummary pus ON pus.PostId = rp.PostId
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
WHERE 
    (rp.UserPostRank = 1 AND ur.Reputation >= 500) OR 
    (rp.UserPostRank > 1 AND ur.Reputation < 500)
ORDER BY 
    rp.CreationDate DESC, ur.Reputation DESC
LIMIT 100;