
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '5 years'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
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
PostMeta AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS EditHistory,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(pm.EditHistory, 'No edits') AS EditDetails,
    pm.LastEditDate,
    rp.Score
FROM 
    RankedPosts rp
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    PostMeta pm ON rp.PostId = pm.PostId
WHERE 
    rp.Rank = 1 AND 
    u.Reputation > 1000 
ORDER BY 
    rp.Score DESC;
