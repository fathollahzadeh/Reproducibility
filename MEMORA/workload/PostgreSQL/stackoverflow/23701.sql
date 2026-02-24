WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation >= 1000
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypeNames,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.Id AS UserId,
    tu.Reputation,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    phs.HistoryTypeNames,
    phs.HistoryCount,
    phs.LastUpdate,
    CASE 
        WHEN tu.Reputation >= 2000 THEN 'Elite User'
        WHEN tu.Reputation BETWEEN 1000 AND 2000 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserTier,
    CASE 
        WHEN phs.LastUpdate IS NULL THEN 'No history available'
        ELSE (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days') || ' votes in the last month'
    END AS RecentVotingActivity
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.RecentPostRank = 1
ORDER BY 
    tu.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;