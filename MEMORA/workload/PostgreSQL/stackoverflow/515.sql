WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts
    FROM 
        UserReputation ur
    LEFT JOIN 
        Posts p ON ur.UserId = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        ur.UserId, ur.Reputation, ur.PostCount, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
)
SELECT 
    au.UserId,
    au.Reputation,
    au.PostCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    COALESCE(SUM(rp.Score), 0) AS TotalScore,
    COUNT(DISTINCT rp.Id) AS TopPosts,
    AVG(rp.Score) AS AvgPostScore,
    CASE 
        WHEN au.ClosedPosts > 0 THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS PostClosureStatus
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId AND rp.Rank <= 3
GROUP BY 
    au.UserId, au.Reputation, au.PostCount, au.GoldBadges, au.SilverBadges, au.BronzeBadges, au.ClosedPosts
ORDER BY 
    au.Reputation DESC, TotalScore DESC
LIMIT 10;