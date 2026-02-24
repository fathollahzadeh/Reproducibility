WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
), UserBadges AS (
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
), PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '<>')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 AND Tags IS NOT NULL
), TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    up.DisplayName AS UserDisplayName,
    r.Title AS TopPostTitle,
    r.CreationDate AS PostCreationDate,
    r.Score AS PostScore,
    tb.Tag AS PopularTag,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts r
JOIN 
    Users up ON r.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
CROSS JOIN 
    TagPopularity tb
WHERE 
    r.rn = 1
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;
