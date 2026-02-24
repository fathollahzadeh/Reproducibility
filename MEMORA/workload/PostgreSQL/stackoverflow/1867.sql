
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    u.DisplayName,
    u.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    ph.EditCount,
    ph.LastEditDate
FROM 
    UserReputation up
JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistories ph ON pp.PostId = ph.PostId
JOIN 
    Users u ON up.UserId = u.Id
WHERE 
    pp.Rank = 1 AND 
    (pp.Score > 10 OR up.Reputation > 1000)
ORDER BY 
    up.Reputation DESC, pp.Score DESC
LIMIT 50;
