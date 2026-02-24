WITH UserBadges AS (
    SELECT 
        b.UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.CreationDate AS TopPostCreationDate,
    CASE 
        WHEN tp.Rank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId AND tp.Rank <= 3
WHERE 
    u.Reputation IS NOT NULL 
    AND u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    u.Reputation DESC, 
    tp.Score DESC NULLS LAST
LIMIT 50;
