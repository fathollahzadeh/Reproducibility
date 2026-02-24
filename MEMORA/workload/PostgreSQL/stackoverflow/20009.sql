WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(rp.Score) AS TotalScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(tp.TotalPosts, 0) AS TotalPosts,
        COALESCE(tp.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        TopPosts tp ON u.Id = tp.OwnerUserId
    WHERE 
        u.Reputation > 1000
),
TopBadgeUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalScore,
    COALESCE(tbu.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(tbu.BadgeNames, 'None') AS GoldBadges
FROM 
    UserStats us
LEFT JOIN 
    TopBadgeUsers tbu ON us.UserId = tbu.UserId
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalScore DESC, us.Reputation DESC;