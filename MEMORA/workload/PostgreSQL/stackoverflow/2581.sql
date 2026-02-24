WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ANSWERCOUNT,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
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
),
LatestPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId = ub.UserId
    WHERE 
        rp.rn = 1
)
SELECT 
    lp.PostId,
    lp.Title,
    lp.CreationDate,
    COALESCE(lp.Score, 0) AS AdjustedScore,
    COALESCE(lp.GoldBadges, 0) AS GoldBadges,
    COALESCE(lp.SilverBadges, 0) AS SilverBadges,
    COALESCE(lp.BronzeBadges, 0) AS BronzeBadges
FROM 
    LatestPosts lp
WHERE 
    lp.Score IS NOT NULL 
    AND lp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Badges' AS Title,
    NULL AS CreationDate,
    SUM(COALESCE(GoldBadges, 0) + COALESCE(SilverBadges, 0) + COALESCE(BronzeBadges, 0)) AS AdjustedScore,
    NULL,
    NULL,
    NULL
FROM 
    UserBadges;