
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserBadges AS (
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
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        ub.GoldBadges IS NOT NULL OR 
        ub.SilverBadges > 0 OR 
        ub.BronzeBadges > 5
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    COALESCE(fp.Score, 0) AS Score,
    CONCAT(
        'Gold: ', COALESCE(fp.GoldBadges, 0), 
        ', Silver: ', COALESCE(fp.SilverBadges, 0), 
        ', Bronze: ', COALESCE(fp.BronzeBadges, 0)
    ) AS BadgeCount
FROM 
    FilteredPosts fp
WHERE 
    fp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
ORDER BY 
    fp.ViewCount DESC 
LIMIT 10;
