
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyGained
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
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
    ur.DisplayName,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalBountyGained,
    COALESCE(ph.CloseReopenCount, 0) AS HalfClosedCount,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS TotalRecentPosts,
    SUM(CASE WHEN ph.FirstClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts
FROM 
    UserReputation ur
LEFT JOIN 
    PostHistoryAggregates ph ON ur.UserId = ph.PostId
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    UserBadges b ON ur.UserId = b.UserId
WHERE 
    ur.Reputation > 1000
GROUP BY 
    ur.DisplayName, ur.Reputation, ur.TotalPosts, ur.TotalBountyGained, b.GoldBadges, b.SilverBadges, b.BronzeBadges, ph.CloseReopenCount
ORDER BY 
    ur.Reputation DESC, ur.TotalPosts DESC;
