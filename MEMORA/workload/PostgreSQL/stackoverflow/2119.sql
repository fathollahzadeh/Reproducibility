
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ub.UserId,
    u.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN rp.rn = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank
FROM 
    UserBadges ub
JOIN 
    Users u ON ub.UserId = u.Id
JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = rp.PostId AND v.UserId = u.Id
WHERE 
    ub.TotalBadges > 0
    AND (v.VoteTypeId = 2 OR v.VoteTypeId IS NULL) 
GROUP BY 
    ub.UserId, u.DisplayName, ub.TotalBadges, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, rp.Title, rp.CreationDate, rp.Score, rp.rn
ORDER BY 
    ub.TotalBadges DESC, rp.Score DESC
LIMIT 100;
