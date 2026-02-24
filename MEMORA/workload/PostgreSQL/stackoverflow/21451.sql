
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id AND p.PostTypeId = 1
    WHERE 
        p.PostTypeId IN (1, 2)  
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    u.DisplayName AS PostOwner,
    up.Reputation AS OwnerReputation,
    up.BadgeCount AS OwnerBadgeCount,
    up.GoldBadges AS GoldBadges,
    up.SilverBadges AS SilverBadges,
    up.BronzeBadges AS BronzeBadges,
    phs.ClosureCount,
    phs.EditCount,
    phs.LastActionDate,
    rp.AcceptedAnswerScore
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation up ON u.Id = up.UserId
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    (phs.EditCount > 5 OR phs.ClosureCount = 1) 
    AND (rp.PostRank = 1 OR rp.AcceptedAnswerScore > 0) 
ORDER BY 
    up.Reputation DESC, rp.CreationDate ASC;
