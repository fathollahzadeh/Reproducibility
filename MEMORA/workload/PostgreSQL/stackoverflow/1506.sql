
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostAndBadgeSummary AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    pas.PostId,
    pas.Title,
    pas.CreationDate,
    COALESCE(pas.Score, 0) AS Score,
    COALESCE(pas.ViewCount, 0) AS ViewCount,
    pas.OwnerDisplayName,
    COALESCE(pas.BadgeCount, 0) AS BadgeCount,
    COALESCE(pas.GoldBadges, 0) AS GoldBadges,
    COALESCE(pas.SilverBadges, 0) AS SilverBadges,
    COALESCE(pas.BronzeBadges, 0) AS BronzeBadges,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pas.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pas.PostId AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    PostAndBadgeSummary pas
WHERE 
    (pas.BadgeCount > 0 OR pas.Score > 10)
ORDER BY 
    pas.CreationDate DESC
LIMIT 50;
