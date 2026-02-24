
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM tag) AS Tag,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            UNNEST(string_to_array(p.Tags, '>')) AS tag
        FROM 
            Posts p
        WHERE 
            p.CreationDate >= CURRENT_DATE - INTERVAL '3 months' AND p.Tags IS NOT NULL
    ) AS TagList
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
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
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(ut.GoldBadges, 0) AS GoldBadges,
    COALESCE(ut.SilverBadges, 0) AS SilverBadges,
    COALESCE(ut.BronzeBadges, 0) AS BronzeBadges,
    STRING_AGG(pt.Tag, ', ') AS PopularTags
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ut ON rp.Id = ut.UserId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT UNNEST(string_to_array(rp.Title, ' ')))
WHERE 
    rp.Score >= 10 AND 
    rp.CommentCount > 5
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.OwnerDisplayName, ut.GoldBadges, ut.SilverBadges, ut.BronzeBadges
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;
