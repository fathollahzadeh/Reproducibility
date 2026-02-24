WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(MAX(v.BountyAmount) OVER (PARTITION BY p.Id), 0) AS MaxBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
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
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
),
ActivePosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        tu.UserRank
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.Id = p.Id
    JOIN 
        TopUsers tu ON p.OwnerUserId = tu.Id
    WHERE 
        rp.Rank = 1
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.Score,
    ap.ViewCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.BadgeCount AS TotalBadges,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    CASE 
        WHEN ap.ViewCount > 1000 THEN 'Popular'
        WHEN ap.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS Popularity,
    ap.UserRank AS OwnerUserRank
FROM 
    ActivePosts ap
JOIN 
    TopUsers tu ON ap.UserRank = tu.UserRank
WHERE 
    tu.BadgeCount > 0
ORDER BY 
    ap.Score DESC, ap.ViewCount DESC
LIMIT 50;